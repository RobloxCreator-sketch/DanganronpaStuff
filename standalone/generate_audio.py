"""Regenerate the game's original audio before importing a fresh source checkout."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parent
RATE = 22050

def write_wav(name, samples):
    with wave.open(str(ROOT / name), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(samples)

samples = bytearray()
for i in range(RATE * 24):
    t = i / RATE
    bass = [55, 55, 65.406, 58.270][int(t // 6) % 4]
    pulse = math.sin(math.tau * bass * t) * math.exp(-(t % .5) * 8) * .14
    pad = (math.sin(math.tau * bass * 4 * t) + math.sin(math.tau * bass * 6 * t)) * .018
    tick = math.sin(math.tau * 1320 * t) * math.exp(-(t % .25) * 100) * .025
    fade = min(1, t / .1, (24 - t) / .1)
    samples.extend(struct.pack('<h', int(max(-1, min(1, (pulse + pad + tick) * fade)) * 32767)))
write_wav('ambience.wav', samples)
write_wav('shot.wav', b''.join(struct.pack('<h', int(math.sin(math.tau * (850*t - 1800*t*t)) * math.exp(-t*30) * 18000)) for t in [i / RATE for i in range(4400)]))
print('Created ambience.wav and shot.wav')
