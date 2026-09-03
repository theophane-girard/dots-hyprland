import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Scope {
    id: root

    enum ActionEnum { Unlock, Poweroff, Reboot }

    signal shouldReFocus()
    signal unlocked(targetAction: var)
    signal failed()

    // These properties are in the context and not individual lock surfaces
    // so all surfaces can share the same state.
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    function resetTargetAction() {
        root.targetAction = LockContext.ActionEnum.Unlock;
    }

    function clearText() {
        root.currentText = "";
    }

    function resetClearTimer() {
        passwordClearTimer.restart();
    }

    function reset() {
        root.resetTargetAction();
        root.clearText();
        root.unlockInProgress = false;
        stopFingerPam();
    }

    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: {
            root.reset();
        }
    }

    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false;
            GlobalStates.screenUnlockFailed = false;
        }
        GlobalStates.screenLockContainsCharacters = currentText.length > 0;
        passwordClearTimer.restart();
    }

    // fprintd-list est asynchrone. Au demarrage l'ecran de verrouillage est leve
    // AVANT que la reponse arrive -- au boot il faut en plus activer fprintd par
    // D-Bus, qui enumere le capteur USB (~2 s). tryFingerUnlock() sortait donc
    // immediatement sur fingerprintsConfigured == false, et plus rien ne le
    // relancait ensuite : l'empreinte restait morte jusqu'au verrouillage
    // suivant. On rearme des que la reponse arrive.
    onFingerprintsConfiguredChanged: {
        if (root.fingerprintsConfigured && GlobalStates.screenLocked && !fingerPam.active) {
            fingerRetryTimer.restart();
        }
    }

    function tryUnlock(alsoInhibitIdle = false) {
        root.alsoInhibitIdle = alsoInhibitIdle;
        root.unlockInProgress = true;
        pam.start();
    }

    function tryFingerUnlock() {
        if (!root.fingerprintsConfigured || !GlobalStates.screenLocked) return;
        if (!fingerPam) {
            root.recreateFingerPam();
            fingerRetryTimer.restart();
            return;
        }
        if (fingerPam.active) {
            // La transaction precedente n'a pas rendu le device : fprintd repond
            // "still busy" et le driver goodixmoc repasse par un reset USB. Cas
            // typique, la sortie de veille -- le ReleaseDevice echoue et le
            // contexte peut rester actif. Ne JAMAIS abandonner ici : un abandon
            // silencieux tue l'empreinte pour tout le reste du verrouillage.
            fingerPam.abort();
            fingerRetryTimer.restart();
            return;
        }
        root.fingerPamStartedAt = Date.now();
        fingerPam.start();
    }

    function stopFingerPam() {
        fingerRetryTimer.stop();
        if (fingerPam && fingerPam.active) {
            fingerPam.abort();
        }
    }

    // Appele au reveil de veille (after_sleep_cmd -> lockFocus). La transaction
    // PAM d'avant la veille est morte avec le device ; on la jette et on repart
    // proprement, sinon plus aucun verify n'est en vol.
    function restartFingerUnlock() {
        if (!GlobalStates.screenLocked) return;
        stopFingerPam();
        root.recreateFingerPam();
        fingerRetryTimer.restart();
    }

    // Chien de garde. Tout le reste -- after_sleep_cmd, la valeur de PamResult au
    // reveil, le succes de l'abort -- est un evenement qui peut ne pas arriver.
    // Celui-ci ne depend d'aucun evenement : tant que l'ecran est verrouille il
    // verifie qu'un verify est bien en vol, et le relance sinon. C'est ce qui
    // rattrape a la fois la course au demarrage et la sortie de veille.
    Timer {
        id: fingerWatchdog
        interval: 5000
        repeat: true
        running: GlobalStates.screenLocked && root.fingerprintsConfigured
        onTriggered: {
            if (!root.fingerPam) {
                root.recreateFingerPam();
                root.tryFingerUnlock();
                return;
            }
            if (!root.fingerPam.active) {
                root.tryFingerUnlock();
                return;
            }
            // Actif depuis trop longtemps : pam_fprintd rend la main en ~30 s, et
            // une veille rend l'ecart enorme. Dans les deux cas le contexte est
            // mort, on le remplace.
            if (root.fingerPamStartedAt > 0 && Date.now() - root.fingerPamStartedAt > 45000) {
                root.recreateFingerPam();
                root.tryFingerUnlock();
            }
        }
    }

    // Laisse a pam_fprintd le temps de terminer son ReleaseDevice avant de relancer
    // un verify. Sans ce delai, les deux transactions se chevauchent.
    Timer {
        id: fingerRetryTimer
        interval: 1500
        onTriggered: root.tryFingerUnlock()
    }

    Process {
        id: fingerprintCheckProc
        running: true
        command: ["bash", "-c", "fprintd-list $(whoami)"]
        stdout: StdioCollector {
            id: fingerprintOutputCollector
            onStreamFinished: {
                root.fingerprintsConfigured = fingerprintOutputCollector.text.includes("Fingerprints for user");
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // console.warn("[LockContext] fprintd-list command exited with error:", exitCode, exitStatus);
                root.fingerprintsConfigured = false;
            }
        }
    }
    
    PamContext {
        id: pam

        // pam_unix will ask for a response for the password prompt
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        // pam_unix won't send any important messages so all we need is the completion status.
        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked(root.targetAction);
                stopFingerPam();
            } else {
                root.clearText();
                root.unlockInProgress = false;
                GlobalStates.screenUnlockFailed = true;
                root.showFailure = true;
            }
        }
    }

    // Le contexte PAM empreinte passe par un Loader pour pouvoir etre DETRUIT
    // puis recree. Apres une veille, pam_fprintd reste coince : son
    // ReleaseDevice echoue ("device is still busy", visible au journal a chaque
    // endormissement) et le contexte ne redevient jamais inactif. Aucun abort()
    // ne le debloque -- la seule issue est d'en fabriquer un neuf.
    property alias fingerPam: fingerPamLoader.item
    property double fingerPamStartedAt: 0

    function recreateFingerPam() {
        console.log("[Lock] contexte PAM empreinte recree");
        fingerPamLoader.active = false;
        fingerPamLoader.active = true;
        root.fingerPamStartedAt = 0;
    }

    Loader {
        id: fingerPamLoader
        active: true
        sourceComponent: PamContext {
            configDirectory: "pam"
            config: "fprintd.conf"

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked(root.targetAction);
                stopFingerPam();
            } else if (GlobalStates.screenLocked) {
                // Relance sur TOUT resultat non-Success, pas seulement Error.
                // Une mise en veille tue le verify en cours ("Cannot run while
                // suspended") et PAM ne remonte pas Error : l'ancienne condition
                // ne rearmait donc jamais, et l'empreinte restait morte jusqu'au
                // deverrouillage suivant. Le garde screenLocked evite qu'un retry
                // parte pendant la sequence de deverrouillage.
                fingerRetryTimer.restart();
            }
        }
        }
    }
}
