"""Synthesise the app's short sound effects into assets/sounds/ (own work, no external samples).

Usage: python tools/make_sounds.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def note(freq: float, dur: float, vol: float = 0.5, shape: str = "sine", attack: float = 0.005,
         release: float = 0.08) -> list[float]:
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        if shape == "sine":
            s = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)
        elif shape == "soft-square":
            s = math.tanh(3 * math.sin(2 * math.pi * freq * t))
        else:
            s = random.uniform(-1, 1)
        env = min(1.0, t / attack) * min(1.0, (dur - t) / release)
        out.append(s * env * vol)
    return out


def mix(*tracks: list[float]) -> list[float]:
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def seq(*parts: list[float], gap: float = 0.0) -> list[float]:
    out: list[float] = []
    for p in parts:
        out += p + [0.0] * int(RATE * gap)
    return out


def save(name: str, samples: list[float]) -> None:
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))
    print(f"{name}.wav  {len(samples) / RATE:.2f}s")


C5, E5, G5, C6, E6, G6, C7 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0, 2093.0

random.seed(7)
save("correct", seq(note(C6, 0.08, 0.45), note(E6, 0.16, 0.45)))
save("wrong", seq(note(220, 0.12, 0.35, "soft-square"), note(174.6, 0.22, 0.35, "soft-square")))
save("combo", seq(note(E6, 0.06, 0.4), note(G6, 0.06, 0.4), note(C7, 0.18, 0.4)))
save("complete", seq(note(C5, 0.1), note(E5, 0.1), note(G5, 0.1), mix(note(C6, 0.45), note(E6, 0.45, 0.3))))
save("levelup", seq(
    note(G5, 0.09), note(C6, 0.09), note(E6, 0.09), note(G6, 0.12),
    mix(note(C6, 0.7, 0.4), note(E6, 0.7, 0.3), note(G6, 0.7, 0.3), note(C7, 0.7, 0.2)),
))
save("tap", note(1800, 0.03, 0.25, release=0.02))
save("flip", [s * (1 - i / 2600) for i, s in enumerate(note(0, 0.12, 0.12, "noise", release=0.1))])
