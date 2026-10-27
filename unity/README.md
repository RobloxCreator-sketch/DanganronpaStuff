# Neon Verdict — Unity edition v0.4

A playable original 3D trial project created and compiled using Unity **6000.6.7f1**, the editor installed on this Mac.

## Open and play

1. In Unity Hub, use Add → Add project from disk and select this **NeonVerdict-Unity** folder.
2. Open it with Unity 6000.6.7f1. Let the editor finish importing.
3. Open **Assets/NeonVerdict/Scenes/Trial.unity**.
4. Press **Play**. The courtroom and UI are generated when play begins; the edit-time scene contains the game controller.

The game begins with a menu. Use Next, Space, or Enter for dialogue. During debate:

- Q/E, mouse wheel, 1/2/3, or cylinder chambers: load evidence.
- Left-click the gold phrase: fire the loaded truth bullet.
- Right-click purple noise: clear it before shooting through it.
- Hold Shift: focus and slow the testimony.
- Tab: open or close the Court Record. Inspecting evidence pauses the debate timer.
- Escape: main menu. M: mute. F11: fullscreen.

Each timed statement focuses the camera on its speaker. Match three contradictions with the evidence, then name the culprit. The selected culprit and placeholder outfit colors vary each launch. There is one short case, with no investigation map, save slots, voice acting, or online multiplayer yet.

## Edit

- `Assets/NeonVerdict/Runtime/TrialCase.cs`: dialogue panels, evidence, correct answers, camera presets, and statement timing.
- `Assets/NeonVerdict/Runtime/NeonVerdictGame.cs`: generated courtroom/characters, Unity UI, portraits, evidence cylinder, input, shooting, scoring, and scene flow.
- `Assets/NeonVerdict/Runtime/TrialCameraRig.cs`: speaker-relative camera tracks.
- `Assets/NeonVerdict/Editor/TrialProjectSetup.cs`: scene generation, validation, and build commands.

Uses the built-in render pipeline, Unity UI (uGUI), and the legacy input backend. No paid assets or external character downloads are required. Audio is synthesized locally. DREditor-derived systems are adapted code; the full beta plugin is not installed in this project. See THIRD_PARTY_NOTICES.md for attribution and the exact reference branch.

## Build

Use **Tools → Neon Verdict → Build Mac Game** or **Build Windows Game**. The Mac module is installed and a Mac build was tested. For Windows, first add **Windows Build Support** to this editor through Unity Hub; it is not installed on this Mac yet.

The provided Mac demo is locally signed, not Apple-notarized. If macOS blocks a downloaded copy, review it in System Settings → Privacy & Security → Open Anyway. Do not disable system security settings.

## Validation

Unity compiled the runtime and editor scripts, generated the scene, and validated all three evidence mappings. The exported Mac app passed the complete automated trial through three contradictions, reasoning scenes, the final verdict, and the expected score. The native app was also launched to inspect its rendering.

To repeat the full game-flow check, launch the built app with `-batchmode -nographics --trial-smoke`. Successful output includes `UNITY TRIAL SMOKE PASS`.
