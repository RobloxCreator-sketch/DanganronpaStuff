# Trial prototype

A first playable courtroom presentation with eight podiums, seven placeholder witnesses, speaker camera cuts, an orbiting debate camera, moving testimony, typewriter dialogue, and the local player's 3D avatar portrait on the left.

## Put the files in Studio

Use your existing file-sync tool to map these files to the matching Explorer locations. GitHub alone does not sync files into Studio. No particular syncing plugin is required.

| File | Studio location | Instance type |
| --- | --- | --- |
| `ServerScriptService/CourtroomBuilder.server.lua` | ServerScriptService | Script |
| `ReplicatedStorage/TrialDialogue.lua` | ReplicatedStorage | ModuleScript named TrialDialogue |
| `StarterPlayer/StarterPlayerScripts/TrialPresentation.client.lua` | StarterPlayer > StarterPlayerScripts | LocalScript |

If your tool cannot import these files, create those three script instances and paste each file's contents into its matching script. You do not need to sync StarterGui: the LocalScript creates the interface in PlayerGui.

Press **Play**, not Run, in Studio. The room is generated above the baseplate and your character is placed at the first podium. Press Space, Enter, controller A, or tap the dialogue area to finish the current text; press again to advance. The final line loops back to the start.

Edit TrialDialogue to change testimony. `speaker` selects podium 1–8, `shot` accepts `wide` or `close`, and `debate = true` activates the orbit camera and moving text.

## Prototype limits and checks

This is a presentation prototype, not a complete multiplayer trial. Players currently share podium 1 and advance their own dialogue independently. Witnesses are basic block stand-ins. No evidence selection, voting, audio, or custom animations yet. The trial anchors the player's character at the podium until the play session ends. Existing map objects are preserved; generated objects live in Workspace > TrialCourtroom.

Live Roblox Studio testing is required; this repository was authored outside Studio. Check: all eight podiums appear; your portrait appears; the first Space completes typing and the next advances; speaker shots change; lines 5–7 orbit with moving text; line 8 replays; the interface remains usable on a phone-sized screen. If StreamingEnabled is on, test with it off for this prototype so the remote courtroom and all speaker models are available to the client.
