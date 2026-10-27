# Neon Verdict — standalone trial demo v0.2

An original single-player 3D courtroom game for macOS and Windows. This project runs independently of Roblox. All models and audio are original and generated locally; the game needs no account or internet connection.

## Play a download

**Mac:** extract NeonVerdict-macOS.zip and open Neon Verdict.app. The first build is ad-hoc signed, not Apple-notarized. If macOS blocks it, review the downloaded app in System Settings → Privacy & Security → Open Anyway. No security settings need to be disabled.

**Windows:** extract NeonVerdict-Windows.zip, then run NeonVerdict.exe. Keep any accompanying files together. This is an unsigned demo; Windows may show a publisher warning.

## Controls

- Click Begin Trial to start.
- Dialogue: Next, Space, or Enter.
- Debate: load a truth bullet with Q / E, the mouse wheel, 1 / 2 / 3, or by clicking a chamber in the revolver cylinder. Aim at the underlined gold phrase and click to fire. White words are neutral. Testimony loops automatically until you break the contradiction; there is no dialogue panel or Next button during debates.
- Hold Shift to slow testimony using a regenerating focus gauge. Tab opens the Court Record and pauses the debate timer while you inspect evidence.
- Each debate has a two-minute timer. Successful contradictions lead to a short reasoning scene before the next debate. Shots recoil the cylinder and show a tracer. Wrong arguments cost confidence; misses only affect accuracy.
- Five false arguments or running out of time loses the case. Break three contradictions, then choose the culprit.
- Escape: main menu. M: mute. F11: toggle fullscreen.

This first case is about a stolen archive seal. The guilty contestant and character appearance palettes are randomized when the game launches. Retrying keeps the current case so you can learn it; relaunching rolls a new cast. A full story, investigation movement, save slots, voice acting, online multiplayer, and custom character art are not included yet.

## Edit or build

If checking out source from GitHub, run `python3 generate_audio.py` first to create the two audio files. The downloadable source ZIP already contains them. Import project.godot in Godot 4.7.2. Main scene: main.tscn. All scene and gameplay code is in main.gd. Export presets target a universal Mac app and Windows x86-64. Install matching export templates through Godot before exporting. On Mac, open Project → Export to build either platform. Windows builds are cross-exported and still need testing on an actual Windows PC.

`Godot --headless --path . -- --smoke-test` runs checks for revolver selection, real keyboard/mouse event routing, Court Record pause, highlighted weak points, automatic testimony loops, reasoning scenes, correct/incorrect evidence, misses, timeout, verdict, scoring, and restart.

## Credits

Original code, character models, case, interface, and synthesized audio were created for this project. The game uses Godot Engine, available under the MIT license. Godot and third-party license details: https://godotengine.org/license/

Godot Engine:
Copyright (c) 2014-present Godot Engine contributors.
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
