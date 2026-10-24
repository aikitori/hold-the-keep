#!/usr/bin/env python3
"""Erzeugt die Musik als nahtlose Schleifen (WAV, mono, 22050 Hz) in assets/audio/music_*.wav.

Reines Python ohne Zusatzpakete: Laute (Karplus-Strong), Flöte (Sinus mit Vibrato), Bordun (Quinte) und für
die Kampfmusik Rahmentrommel und Schellen. Die Melodie entsteht aus einem festen Zufallsstartwert, jeder Lauf
ergibt also dieselben Dateien.

Nutzung: python3 tools/make_music.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"

# D-Dorisch: d e f g a h c
SCALE = [0, 2, 3, 5, 7, 9, 10]
D3 = 146.83


def freq(degree, octave=0):
    """Stufe der Tonleiter (0 = d) -> Frequenz, Oktaven über D3."""
    octave += degree // 7
    return D3 * 2 ** ((SCALE[degree % 7] + 12 * octave) / 12)


def pluck(buf, start, f, dur, gain):
    """Laute: Karplus-Strong, gedämpfte Saite."""
    period = max(2, int(RATE / f))
    rng = random.Random(int(f * 1000) + start)
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    n = int(dur * RATE)
    for i in range(n):
        j = i % period
        value = ring[j]
        ring[j] = 0.497 * (value + ring[(j + 1) % period])
        buf[(start + i) % len(buf)] += value * gain


def flute(buf, start, f, dur, gain):
    """Flöte: Sinus mit leichtem Oberton, Vibrato, weichem Ein- und Ausschwingen."""
    n = int(dur * RATE)
    attack, release = int(0.06 * RATE), int(0.12 * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        env = min(1.0, i / attack) * min(1.0, (n - i) / release)
        vib = 1 + 0.006 * math.sin(2 * math.pi * 5.2 * t) * min(1.0, t * 3)
        phase += 2 * math.pi * f * vib / RATE
        buf[(start + i) % len(buf)] += (math.sin(phase) + 0.18 * math.sin(2 * phase)) * env * gain


def drone(buf, f, gain):
    """Bordun über die ganze Schleife: weiche Sägezahn-Quinte durch einen Tiefpass."""
    low = 0.0
    phases = [0.0, 0.0]
    n = len(buf)
    for i in range(n):
        swell = 0.75 + 0.25 * math.sin(2 * math.pi * i / n * 2)  # zweimal je Schleife, nahtlos
        value = 0.0
        for k, ratio in enumerate((1.0, 1.5)):
            phases[k] = (phases[k] + f * ratio / RATE) % 1.0
            value += 2 * phases[k] - 1
        low += 0.02 * (value - low)
        buf[i] += low * gain * swell


def drum(buf, start, gain):
    """Rahmentrommel: fallender Sinus mit kurzem Rauschen."""
    rng = random.Random(start)
    n = int(0.35 * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 55 + 70 * math.exp(-t * 30)
        phase += 2 * math.pi * f / RATE
        env = math.exp(-t * 11)
        noise = rng.uniform(-1, 1) * math.exp(-t * 60) * 0.3
        buf[(start + i) % len(buf)] += (math.sin(phase) + noise) * env * gain


def jingle(buf, start, gain):
    """Schellen: kurzes, hohes Rauschen."""
    rng = random.Random(start * 7)
    n = int(0.09 * RATE)
    last = 0.0
    for i in range(n):
        value = rng.uniform(-1, 1)
        high = value - last  # grober Hochpass
        last = value
        buf[(start + i) % len(buf)] += high * math.exp(-i / RATE * 45) * gain


def melody(rng, bars, chords, per_bar):
    """Melodie: kleine Schritte in der Tonleiter, auf Akkordtönen beginnen und enden."""
    notes = []
    degree = chords[0]
    for bar in range(bars):
        chord = chords[bar % len(chords)]
        tones = [chord, chord + 2, chord + 4]
        for beat in range(per_bar):
            if beat == 0:
                degree = min(tones, key=lambda d: abs(d - degree) + rng.random())
            else:
                degree += rng.choice([-2, -1, -1, 1, 1, 2, 0])
                degree = max(2, min(11, degree))
            rest = beat == per_bar - 1 and bar % 2 == 1
            notes.append(None if rest else degree)
    notes[-1] = None
    return notes


def render(name, bpm, bars, chords, battle):
    beat = 60 / bpm
    n = int(bars * 4 * beat * RATE)
    buf = [0.0] * n
    rng = random.Random(name)
    drone(buf, D3 / 2, 0.10)
    # Laute: Akkordtöne als Achtel (Kampf: dazu Sechzehntel auf Zählzeit 4)
    for bar in range(bars):
        chord = chords[bar % len(chords)]
        pattern = [0, 2, 4, 2, 7, 4, 2, 4]
        for k, step in enumerate(pattern):
            start = int((bar * 4 + k * 0.5) * beat * RATE)
            pluck(buf, start, freq(chord + step, -1), 1.2, 0.30 if k % 2 == 0 else 0.22)
        if battle:
            for k in range(2):
                start = int((bar * 4 + 3 + 0.5 + k * 0.25) * beat * RATE)
                pluck(buf, start, freq(chord + 4, -1), 0.6, 0.15)
    # Flöte: Viertel (Bauphase: halbe Noten, ruhiger)
    per_bar = 4 if battle else 2
    notes = melody(rng, bars, chords, per_bar)
    length = 4 / per_bar
    for i, degree in enumerate(notes):
        if degree is not None:
            start = int(i * length * beat * RATE)
            flute(buf, start, freq(degree), length * beat * 0.95, 0.16 if battle else 0.14)
    if battle:
        for bar in range(bars):
            for b in (0, 1.5, 2, 3):
                drum(buf, int((bar * 4 + b) * beat * RATE), 0.55 if b in (0, 2) else 0.35)
            for b in (0.5, 1.5, 2.5, 3.5):
                jingle(buf, int((bar * 4 + b) * beat * RATE), 0.10)
    peak = max(abs(v) for v in buf)
    scale = 0.89 / peak
    path = OUT / f"music_{name}.wav"
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(v * scale * 32767)) for v in buf))
    print(f"{path.name}: {n / RATE:.1f} s")


if __name__ == "__main__":
    # Akkorde als Stufen: 0 d-Moll, 3 G-Dur (macht es dorisch), 4 a-Moll, 6 C-Dur
    render("build", 76, 16, [0, 6, 0, 4, 3, 6, 4, 0], battle=False)
    render("battle", 126, 16, [0, 6, 0, 4, 0, 3, 6, 4], battle=True)
