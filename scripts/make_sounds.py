#!/usr/bin/env python3
"""칩튠 스타일 효과음·배경음악을 합성해 Resources/Sounds/*.wav 로 저장한다.
외부 의존성 없음 (표준 라이브러리만 사용). 다시 만들려면: python3 scripts/make_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "Resources" / "Sounds"


def square(freq, t, duty=0.5):
    return 1.0 if (t * freq) % 1.0 < duty else -1.0


def triangle(freq, t):
    p = (t * freq) % 1.0
    return 4.0 * abs(p - 0.5) - 1.0


def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)


def write_wav(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print(f"saved {path.relative_to(OUT.parent.parent)} ({len(samples) / SR:.2f}s)")


def make_jump():
    # 위로 쓸어올리는 블립 (250→650Hz, 90ms)
    n = int(SR * 0.09)
    out = []
    for i in range(n):
        t = i / SR
        p = i / n
        freq = 250 + 400 * p
        env = (1 - p) ** 1.5
        out.append(square(freq, t, duty=0.4) * 0.5 * env)
    return out


def make_land():
    # 낮은 툭 소리 (110Hz, 55ms)
    n = int(SR * 0.055)
    out = []
    for i in range(n):
        t = i / SR
        p = i / n
        env = (1 - p) ** 2
        out.append((sine(110, t) * 0.8 + triangle(220, t) * 0.2) * 0.45 * env)
    return out


def make_die():
    # 하강 멜로디 + 마지막 낮은 음 (0.45s)
    out = []
    notes = [(392, 0.09), (330, 0.09), (262, 0.09), (196, 0.18)]
    for freq, dur in notes:
        n = int(SR * dur)
        for i in range(n):
            t = i / SR
            p = i / n
            env = (1 - p) ** 1.2
            out.append(square(freq, t, duty=0.5) * 0.5 * env)
    return out


def make_bgm():
    # 조용한 I–vi–IV–V 루프 (C–Am–F–G, 8초, 120bpm)
    # 베이스 = 사인 2분음표, 아르페지오 = 삼각파 8분음표
    beat = 0.5  # 120bpm
    bars = [
        (65.41, [261.6, 329.6, 392.0, 329.6]),   # C:  C2 / C4 E4 G4 E4
        (55.00, [220.0, 261.6, 329.6, 261.6]),   # Am: A1 / A3 C4 E4 C4
        (87.31, [174.6, 220.0, 261.6, 220.0]),   # F:  F2 / F3 A3 C4 A3
        (98.00, [196.0, 246.9, 293.7, 246.9]),   # G:  G2 / G3 B3 D4 B3
    ]
    total = int(SR * beat * 16)  # 4마디 × 4박
    out = [0.0] * total

    for bar_index, (bass, arp) in enumerate(bars):
        bar_start = bar_index * 4 * beat
        # 베이스: 1·3박에 2분음표
        for beat_offset in (0.0, 2.0):
            start = int(SR * (bar_start + beat_offset * beat))
            n = int(SR * beat * 2)
            for i in range(n):
                t = i / SR
                env = min(1.0, i / (SR * 0.01)) * (1 - i / n) ** 0.7
                idx = start + i
                if idx < total:
                    out[idx] += sine(bass, t) * 0.16 * env
        # 아르페지오: 8분음표 패턴 ×2
        for rep in range(2):
            for note_index, freq in enumerate(arp):
                start = int(SR * (bar_start + (rep * 4 + note_index) * beat * 0.5))
                n = int(SR * beat * 0.5)
                for i in range(n):
                    t = i / SR
                    env = min(1.0, i / (SR * 0.005)) * (1 - i / n) ** 1.5
                    idx = start + i
                    if idx < total:
                        out[idx] += triangle(freq, t) * 0.10 * env
    return out


write_wav("jump.wav", make_jump())
write_wav("land.wav", make_land())
write_wav("die.wav", make_die())
write_wav("bgm.wav", make_bgm())
