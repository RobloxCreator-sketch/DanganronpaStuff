# DREditor attribution and adaptation notes

Neon Verdict Unity edition v0.4 adapts selected systems from **DREditor**, by Benjamin "Sweden" Jillson, SeleniumSoul, and the DREditor contributors.

Source repository: https://github.com/CertifiedSharp/DREditor
Reference branch: Alpha
Reference commit: d80bb588a4dff44acf7612627c23a91cb96c4c8e
Branch license: Creative Commons Attribution 4.0 International (CC BY 4.0)
License: https://creativecommons.org/licenses/by/4.0/
Legal code: https://creativecommons.org/licenses/by/4.0/legalcode
Original license notice: https://github.com/CertifiedSharp/DREditor/blob/d80bb588a4dff44acf7612627c23a91cb96c4c8e/LICENSE.md

The reference branch's license applies to the adaptations identified below. The beta package on main declares a different license; this adaptation uses the Alpha branch identified above.

## Adapted systems and changes

- `trial_camera.gd`: GDScript rewrite of the seat-focused radius/height camera structure in `Scripts/Camera/TrialCamera/DRTrialCamera.cs`, authored by SeleniumSoul. Unity pivots, Quaternion interpolation, and Animator tracks were replaced with Godot transforms, procedural shot presets, transitions, and field-of-view animation.
- `trial_case.gd`: Godot data model adapted from the panel, phrase, speaker, timing, camera, and evidence-answer structure in `SwedenGang/Scripts/Trial/NSD/NSDBuilder.cs` and `Scripts/Dialogues/TrialDialogue.cs`. All mystery text, speaker roles, timings, and camera presets in this case are original.
- `main.gd`: adaptation of the loaded-bullet animation/fire lock, evidence text firing, noise-blocking/silencer interactions, phrase checking, and counter sequence described in `SwedenGang/Scripts/Trial/NSD/NSDManager.cs`, `NSDBullet.cs`, `NSDReticle.cs`, `PhraseText.cs`, and `WhiteNoiseText.cs`, authored by Benjamin "Sweden" Jillson. These systems were rewritten for Godot's input, controls, and tweens; screen-space hit detection replaces Unity physics raycasts. Bullet impacts use click-time targeting and a brief animated flight. The original +5/-3 silencer and -15 blocked-shot time adjustments were retained. No original art, character sprites, voices, music, shaders, or Unity dependency code were included.

DREditor and its contributors do not endorse this project. Attribution does not grant rights to third-party franchise assets.

## Godot Engine

Godot Engine and its third-party component licenses are documented at https://godotengine.org/license/ and in this project's README.

## Unity edition modifications

The Unity edition implements the adapted systems in `TrialCase.cs`, `TrialCameraRig.cs`, and `NeonVerdictGame.cs`. These are new C# implementations of the previously adapted Godot systems described above, with Unity Canvas/uGUI rendering, RenderTexture portraits, procedural primitive models, and native Unity input/audio. The reference project's full plugin, art, prefab library, dependency plugins, and franchise assets are not bundled.

The Godot license note above concerns the earlier Godot edition; this Unity project does not distribute Godot Engine. Unity Editor and player components are provided under Unity's own applicable license terms.
