#!/usr/bin/env python3
"""Generates the game's sound effects and music as 16-bit mono WAV files.

All audio is synthesised from scratch (oscillators, filtered noise and simple
envelopes), so the project ships no third-party audio. Run from the project
root to rebuild everything in assets/audio/:

    python3 tools/generate_audio.py

Needs Python 3 and numpy. Output is deterministic (fixed random seed).
"""

from __future__ import annotations

import os
import wave

import numpy as np

SFX_RATE = 44100
MUSIC_RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
RNG = np.random.default_rng(1979)


# --- building blocks -------------------------------------------------------

def timeline(seconds: float, rate: int) -> np.ndarray:
    return np.arange(int(seconds * rate)) / rate


def phase_of(freq: np.ndarray | float, n: int, rate: int) -> np.ndarray:
    """Running phase (in cycles) for a possibly time-varying frequency."""
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    return np.cumsum(f) / rate


def square(freq, n, rate, duty=0.5):
    return np.where(phase_of(freq, n, rate) % 1.0 < duty, 1.0, -1.0)


def saw(freq, n, rate):
    return 2.0 * (phase_of(freq, n, rate) % 1.0) - 1.0


def triangle(freq, n, rate):
    return 2.0 * np.abs(saw(freq, n, rate)) - 1.0


def sine(freq, n, rate):
    return np.sin(2.0 * np.pi * phase_of(freq, n, rate))


def noise(n):
    return RNG.uniform(-1.0, 1.0, n)


def lowpass(signal: np.ndarray, cutoff, rate: int) -> np.ndarray:
    """One-pole low-pass; `cutoff` may vary over time."""
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), signal.shape)
    alpha = 1.0 - np.exp(-2.0 * np.pi * c / rate)
    out = np.empty_like(signal)
    y = 0.0
    for i, x in enumerate(signal):
        y += alpha[i] * (x - y)
        out[i] = y
    return out


def highpass(signal: np.ndarray, cutoff: float, rate: int) -> np.ndarray:
    return signal - lowpass(signal, cutoff, rate)


def envelope(n: int, rate: int, attack: float, decay_power: float = 1.0) -> np.ndarray:
    """Linear attack then a decay to silence shaped by `decay_power`."""
    t = np.arange(n) / rate
    length = n / rate
    env = np.clip(t / max(attack, 1e-4), 0.0, 1.0)
    tail = np.clip(1.0 - (t - attack) / max(length - attack, 1e-4), 0.0, 1.0)
    return env * tail ** decay_power


def adsr(n: int, rate: int, a: float, d: float, s: float, r: float) -> np.ndarray:
    t = np.arange(n) / rate
    length = n / rate
    env = np.where(t < a, t / max(a, 1e-4), 1.0)
    env = np.where((t >= a) & (t < a + d), 1.0 - (1.0 - s) * (t - a) / max(d, 1e-4), env)
    env = np.where(t >= a + d, s, env)
    release_start = max(length - r, 0.0)
    env = np.where(t >= release_start, env * np.clip((length - t) / max(r, 1e-4), 0.0, 1.0), env)
    return env


def normalize(signal: np.ndarray, peak: float) -> np.ndarray:
    m = np.max(np.abs(signal))
    return signal if m == 0 else signal * (peak / m)


def fade_edges(signal: np.ndarray, rate: int, fade: float = 0.004) -> np.ndarray:
    k = min(int(fade * rate), len(signal) // 2)
    if k > 0:
        ramp = np.linspace(0.0, 1.0, k)
        signal[:k] *= ramp
        signal[-k:] *= ramp[::-1]
    return signal


def write_wav(path: str, signal: np.ndarray, rate: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = (np.clip(signal, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(data.tobytes())
    print(f"{os.path.relpath(path, ROOT):34s} {len(signal) / rate:6.2f}s")


def note_hz(midi: float) -> float:
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def tone_sequence(notes, step: float, rate: int, wave_fn=square, decay: float = 1.5, duty=0.5):
    """Back-to-back notes (MIDI numbers, None = rest) of `step` seconds each."""
    parts = []
    n_step = int(step * rate)
    for note in notes:
        if note is None:
            parts.append(np.zeros(n_step))
            continue
        if wave_fn is square:
            tone = square(note_hz(note), n_step, rate, duty)
        else:
            tone = wave_fn(note_hz(note), n_step, rate)
        parts.append(tone * envelope(n_step, rate, 0.003, decay))
    return np.concatenate(parts)


# --- sound effects ---------------------------------------------------------

def sfx_laser():
    r = SFX_RATE
    n = int(0.14 * r)
    t = np.arange(n) / r
    freq = 1500.0 * np.exp(-t * 16.0) + 380.0
    s = square(freq, n, r, 0.3) * 0.6 + saw(freq * 0.5, n, r) * 0.4
    return normalize(lowpass(s, 6000.0, r) * envelope(n, r, 0.002, 1.6), 0.7)


def sfx_enemy_laser():
    r = SFX_RATE
    n = int(0.22 * r)
    t = np.arange(n) / r
    freq = (760.0 * np.exp(-t * 9.0) + 170.0) * (1.0 + 0.06 * np.sin(2 * np.pi * 38.0 * t))
    s = square(freq, n, r, 0.5)
    return normalize(lowpass(s, 3500.0, r) * envelope(n, r, 0.002, 1.3), 0.6)


def explosion(seconds: float, cutoff_start: float, cutoff_end: float, thump_hz: float,
              crackle: float = 0.0):
    r = SFX_RATE
    n = int(seconds * r)
    t = np.arange(n) / r
    cutoff = cutoff_end + (cutoff_start - cutoff_end) * np.exp(-t * 6.0 / seconds)
    body = lowpass(noise(n), cutoff, r)
    thump = sine(thump_hz * np.exp(-t * 3.0), n, r) * np.exp(-t * 9.0)
    s = body * 1.6 + thump * 0.9
    if crackle > 0.0:
        sparks = (RNG.random(n) < 0.004) * RNG.uniform(-1.0, 1.0, n)
        s += lowpass(sparks, 5000.0, r) * crackle * np.exp(-t * 4.0)
    return normalize(s * envelope(n, r, 0.004, 2.2), 0.9)


def sfx_asteroid_explode():
    return explosion(0.65, 3200.0, 180.0, 90.0, crackle=2.0)


def sfx_ufo_explode():
    r = SFX_RATE
    boom = explosion(1.0, 4200.0, 220.0, 70.0, crackle=3.0)
    n = len(boom)
    t = np.arange(n) / r
    whine = square(1100.0 * np.exp(-t * 2.6) + 60.0, n, r, 0.25) * np.exp(-t * 3.5) * 0.35
    return normalize(boom + lowpass(whine, 4000.0, r), 0.9)


def sfx_player_explode():
    r = SFX_RATE
    boom = explosion(1.6, 2600.0, 90.0, 55.0, crackle=2.5)
    n = len(boom)
    t = np.arange(n) / r
    fall = saw(520.0 * np.exp(-t * 1.6) + 40.0, n, r) * np.exp(-t * 2.0) * 0.3
    return normalize(boom + lowpass(fall, 2200.0, r), 0.95)


def sfx_thrust_loop():
    """Seamless engine rumble; the game varies its volume and pitch with thrust."""
    r = SFX_RATE
    n = int(1.0 * r)
    lead = int(0.25 * r)  # warms up the filters before the loop starts
    k = int(0.05 * r)  # crossfade length
    total = lead + n + k
    raw = noise(total)
    body = lowpass(raw, 420.0, r) * 2.2 + lowpass(raw, 1600.0, r) * 0.35
    body *= 1.0 + 0.12 * np.sin(2 * np.pi * 7.0 * np.arange(total) / r)
    s = (body + sine(55.0, total, r) * 0.25 + sine(110.0, total, r) * 0.12)[lead:]
    # The loop's end runs straight into what was rendered after it, so blending
    # that continuation into the start makes the wrap-around seamless.
    loop = s[:n].copy()
    ramp = np.linspace(0.0, 1.0, k)
    loop[:k] = s[n:n + k] * (1.0 - ramp) + s[:k] * ramp
    return normalize(loop, 0.6)


def sfx_boost():
    r = SFX_RATE
    n = int(0.55 * r)
    t = np.arange(n) / r
    cutoff = 400.0 + 5200.0 * (t / t[-1]) ** 0.6
    whoosh = lowpass(noise(n), cutoff, r) * 1.8
    rise = saw(180.0 + 900.0 * (t / t[-1]) ** 1.5, n, r) * 0.25
    s = (whoosh + lowpass(rise, 3000.0, r)) * adsr(n, r, 0.05, 0.1, 0.8, 0.3)
    return normalize(s, 0.75)


def sfx_pickup():
    r = SFX_RATE
    s = tone_sequence([72, 76, 79, 84, 88], 0.055, r, square, 1.2, 0.25)
    s = np.concatenate([s, np.zeros(int(0.08 * r))])
    echo = np.zeros_like(s)
    d = int(0.07 * r)
    echo[d:] = s[:-d] * 0.35
    return normalize(lowpass(s + echo, 7000.0, r), 0.6)


def sfx_shield_hit():
    r = SFX_RATE
    n = int(0.5 * r)
    t = np.arange(n) / r
    mod = sine(310.0, n, r) * 380.0 * np.exp(-t * 6.0)
    ring = sine(620.0 + mod, n, r) * np.exp(-t * 7.0)
    zap = lowpass(noise(n), 6000.0, r) * np.exp(-t * 30.0) * 0.5
    return normalize(ring + zap, 0.7)


def sfx_wave_start():
    r = SFX_RATE
    a = tone_sequence([67, None, 74], 0.11, r, square, 1.0, 0.5)
    b = tone_sequence([79], 0.42, r, square, 1.8, 0.5)
    s = np.concatenate([a, b])
    sub = np.concatenate([tone_sequence([55, None, 62], 0.11, r, triangle, 1.0),
                          tone_sequence([67], 0.42, r, triangle, 1.8)])
    return normalize(lowpass(s * 0.55 + sub * 0.6, 5000.0, r), 0.6)


def sfx_wave_complete():
    r = SFX_RATE
    s = tone_sequence([72, 76, 79, 84, 79, 84, 88], 0.075, r, square, 1.0, 0.25)
    tail = tone_sequence([91], 0.45, r, square, 2.0, 0.25)
    s = np.concatenate([s, tail])
    return normalize(lowpass(s, 6500.0, r), 0.55)


def sfx_extra_life():
    r = SFX_RATE
    s = tone_sequence([84, 88, 91, 84, 88, 91, 96], 0.06, r, square, 1.0, 0.125)
    return normalize(lowpass(np.concatenate([s, np.zeros(int(0.05 * r))]), 7000.0, r), 0.5)


def sfx_ui_move():
    r = SFX_RATE
    n = int(0.045 * r)
    return normalize(square(1180.0, n, r, 0.25) * envelope(n, r, 0.001, 2.0), 0.3)


def sfx_ui_select():
    r = SFX_RATE
    s = tone_sequence([79, 86], 0.05, r, square, 1.4, 0.25)
    return normalize(lowpass(s, 7000.0, r), 0.4)


def sfx_ui_back():
    r = SFX_RATE
    s = tone_sequence([81, 74], 0.05, r, square, 1.4, 0.25)
    return normalize(lowpass(s, 6000.0, r), 0.35)


def sfx_game_over():
    r = SFX_RATE
    s = tone_sequence([67, 66, 65], 0.28, r, square, 0.6, 0.5)
    last_n = int(1.1 * r)
    t = np.arange(last_n) / r
    vibrato = note_hz(64) * (1.0 + 0.012 * np.sin(2 * np.pi * 6.0 * t))
    last = square(vibrato, last_n, r, 0.5) * envelope(last_n, r, 0.01, 1.4)
    s = np.concatenate([s, last])
    bass = np.concatenate([tone_sequence([43, 42, 41], 0.28, r, triangle, 0.6),
                           triangle(note_hz(40), last_n, r) * envelope(last_n, r, 0.01, 1.4)])
    return normalize(lowpass(s * 0.5 + bass * 0.6, 3500.0, r), 0.65)


SFX = {
    "laser": sfx_laser,
    "enemy_laser": sfx_enemy_laser,
    "asteroid_explode": sfx_asteroid_explode,
    "ufo_explode": sfx_ufo_explode,
    "player_explode": sfx_player_explode,
    "thrust_loop": sfx_thrust_loop,
    "boost": sfx_boost,
    "pickup": sfx_pickup,
    "shield_hit": sfx_shield_hit,
    "wave_start": sfx_wave_start,
    "wave_complete": sfx_wave_complete,
    "extra_life": sfx_extra_life,
    "ui_move": sfx_ui_move,
    "ui_select": sfx_ui_select,
    "ui_back": sfx_ui_back,
    "game_over": sfx_game_over,
}


# --- music -----------------------------------------------------------------

class Track:
    """A fixed-length buffer that notes are mixed into; overflow wraps to the
    start so the finished buffer loops without a click or a gap."""

    def __init__(self, bpm: float, bars: int, rate: int = MUSIC_RATE):
        self.rate = rate
        self.beat = 60.0 / bpm
        self.length = int(round(bars * 4 * self.beat * rate))
        self.buffer = np.zeros(self.length)

    def add(self, start_beat: float, signal: np.ndarray, gain: float = 1.0) -> None:
        start = int(round(start_beat * self.beat * self.rate)) % self.length
        pos = 0
        while pos < len(signal):
            room = min(self.length - start, len(signal) - pos)
            self.buffer[start:start + room] += signal[pos:pos + room] * gain
            pos += room
            start = 0

    def note(self, start_beat, beats, midi, wave_fn=square, gain=1.0, duty=0.5,
             a=0.005, d=0.08, s=0.6, rel=0.08, cutoff=None):
        n = int(beats * self.beat * self.rate)
        f = note_hz(midi)
        tone = square(f, n, self.rate, duty) if wave_fn is square else wave_fn(f, n, self.rate)
        tone = tone * adsr(n, self.rate, a, d, s, rel)
        if cutoff is not None:
            tone = lowpass(tone, cutoff, self.rate)
        self.add(start_beat, tone, gain)

    def kick(self, start_beat, gain=1.0):
        n = int(0.22 * self.rate)
        t = np.arange(n) / self.rate
        k = sine(48.0 + 110.0 * np.exp(-t * 32.0), n, self.rate) * np.exp(-t * 14.0)
        self.add(start_beat, k, gain)

    def snare(self, start_beat, gain=1.0):
        n = int(0.18 * self.rate)
        t = np.arange(n) / self.rate
        body = highpass(noise(n), 900.0, self.rate) * np.exp(-t * 20.0)
        tone = sine(190.0, n, self.rate) * np.exp(-t * 30.0) * 0.5
        self.add(start_beat, body + tone, gain)

    def hat(self, start_beat, gain=1.0, length=0.05):
        n = int(length * self.rate)
        t = np.arange(n) / self.rate
        h = highpass(noise(n), 5000.0, self.rate) * np.exp(-t * 70.0)
        self.add(start_beat, h, gain)


# A minor: Am - F - C - G, as (root, chord tones) in MIDI.
PROGRESSION = [
    (45, [57, 60, 64]),
    (41, [57, 60, 65]),
    (48, [55, 60, 64]),
    (43, [55, 59, 62]),
]


def music_menu():
    track = Track(bpm=84, bars=8)
    for bar in range(8):
        root, chord = PROGRESSION[(bar // 2) % 4]
        start = bar * 4
        # Soft pad: detuned triangles with slow attack.
        for midi in chord:
            for detune in (-0.06, 0.06):
                track.note(start, 4.0, midi + detune, triangle, 0.11, a=0.6, d=0.5, s=0.8, rel=0.6)
        track.note(start, 4.0, root, triangle, 0.28, a=0.05, d=0.4, s=0.7, rel=0.4)
        # Gentle eighth-note arpeggio.
        arp = [chord[0], chord[1], chord[2], chord[1] + 12, chord[2], chord[1], chord[0] + 12, chord[2]]
        for i, midi in enumerate(arp):
            track.note(start + i * 0.5, 0.45, midi + 12, square, 0.05, duty=0.25,
                       a=0.004, d=0.12, s=0.25, rel=0.1, cutoff=2600.0)
    return normalize(track.buffer, 0.5)


GAME_BPM = 128
GAME_BARS = 8


def music_game_base():
    track = Track(bpm=GAME_BPM, bars=GAME_BARS)
    for bar in range(GAME_BARS):
        root, chord = PROGRESSION[bar % 4]
        start = bar * 4
        # Driving eighth-note bass with an octave bounce.
        for i in range(8):
            midi = root + (12 if i % 4 == 3 else 0)
            track.note(start + i * 0.5, 0.42, midi, saw, 0.32, a=0.003, d=0.1, s=0.5,
                       rel=0.05, cutoff=900.0)
        for beat in range(4):
            track.kick(start + beat, 0.9)
            track.hat(start + beat + 0.5, 0.25)
        for midi in chord:
            track.note(start, 4.0, midi, triangle, 0.07, a=0.2, d=0.5, s=0.7, rel=0.4)
    return track.buffer


def music_game_intensity():
    """Extra layer faded in on later waves: lead arpeggio, snare and 16th hats."""
    track = Track(bpm=GAME_BPM, bars=GAME_BARS)
    for bar in range(GAME_BARS):
        root, chord = PROGRESSION[bar % 4]
        start = bar * 4
        pattern = [0, 1, 2, 1, 2, 0, 1, 2]
        for i in range(16):
            midi = chord[pattern[i % 8]] + (12 if i % 8 >= 4 else 0) + 12
            track.note(start + i * 0.25, 0.22, midi, square, 0.07, duty=0.25,
                       a=0.002, d=0.06, s=0.3, rel=0.04, cutoff=3200.0)
        track.snare(start + 1, 0.5)
        track.snare(start + 3, 0.5)
        for i in range(16):
            track.hat(start + i * 0.25, 0.12 if i % 2 else 0.18, 0.03)
    return track.buffer


def write_game_music(folder: str) -> None:
    base = music_game_base()
    layer = music_game_intensity()
    # Shared scale so the two stems keep their relative levels when combined.
    peak = np.max(np.abs(base + layer))
    write_wav(os.path.join(folder, "game_base.wav"), base * (0.5 / peak), MUSIC_RATE)
    write_wav(os.path.join(folder, "game_intensity.wav"), layer * (0.5 / peak), MUSIC_RATE)


def main() -> None:
    for name, build in SFX.items():
        signal = build()
        if name != "thrust_loop":
            signal = fade_edges(signal, SFX_RATE)
        write_wav(os.path.join(ROOT, "sfx", f"{name}.wav"), signal, SFX_RATE)
    music = os.path.join(ROOT, "music")
    write_wav(os.path.join(music, "menu.wav"), music_menu(), MUSIC_RATE)
    write_game_music(music)


if __name__ == "__main__":
    main()
