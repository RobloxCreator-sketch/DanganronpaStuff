extends RefCounted
# Data-driven panel structure adapted from DREditor Alpha's NSDBuilder/TrialDialogue.
# DREditor contributors: Benjamin "Sweden" Jillson and SeleniumSoul; CC BY 4.0.
# Rewritten for Godot with original text, camera presets, and case content.
# Full source and modification details: THIRD_PARTY_NOTICES.md.
const DEBATES = [
    [
        {"role": "witness", "text": "The archive should have been empty.", "duration": 4.5, "shot": "sweep_left"},
        {"role": "culprit", "prefix": "I ", "weak": "NEVER ENTERED THE ARCHIVE", "suffix": ".", "answer": 0, "duration": 6.0, "shot": "push_in", "noise": "THAT PROVES NOTHING"},
        {"role": "observer", "text": "Someone's personal key was recorded.", "duration": 4.0, "shot": "high_angle"}
    ],
    [
        {"role": "observer", "text": "The display lock wasn't forced.", "duration": 4.0, "shot": "sweep_right"},
        {"role": "culprit", "prefix": "I never touched ", "weak": "THAT CABINET", "suffix": ". Not once.", "answer": 1, "duration": 6.0, "shot": "dolly_zoom", "noise": "YOU'RE JUST GUESSING"},
        {"role": "witness", "text": "A fiber was caught inside the display.", "duration": 4.0, "shot": "push_in"}
    ],
    [
        {"role": "witness", "text": "The clock stopped at nine.", "duration": 4.0, "shot": "high_angle"},
        {"role": "observer", "text": "We found its battery on the floor.", "duration": 4.5, "shot": "sweep_left"},
        {"role": "culprit", "prefix": "A ", "weak": "POWER CUT", "suffix": " stopped the clock.", "answer": 2, "duration": 6.0, "shot": "dolly_zoom", "noise": "IT'S OBVIOUS"}
    ]

]
