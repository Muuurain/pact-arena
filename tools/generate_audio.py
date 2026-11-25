"""
Procedural dark-cyber roguelite audio generator for Pact Arena (血契竞技场).
Upgraded stereo DSP engine using biquad filtering, FM metallic synthesis,
sub-bass impact shaping, stereo widening/chorus, short arena reflections,
and LibVorbis OGG encoding via FFmpeg.
"""
import argparse
import math
import subprocess
import tempfile
import wave
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
AUDIO = ROOT / "assets" / "audio"
FFMPEG = Path(r"D:\ffmpeg\ffmpeg-2025-02-26-git-99e2af4e78-full_build\ffmpeg-2025-02-26-git-99e2af4e78-full_build\bin\ffmpeg.exe")
SR = 44100


def ensure_dirs() -> None:
    (AUDIO / "sfx").mkdir(parents=True, exist_ok=True)
    (AUDIO / "bgm").mkdir(parents=True, exist_ok=True)


def to_stereo(sig: np.ndarray) -> np.ndarray:
    """Ensure shape (N, 2) stereo float64 array."""
    if sig.ndim == 1:
        return np.column_stack((sig, sig)).astype(np.float64)
    return sig.astype(np.float64)


def save_ogg(samples: np.ndarray, out_path: Path, bitrate: str = "144k") -> None:
    st = to_stereo(samples)
    # Anti-click micro fades
    fade_in = min(int(0.002 * SR), len(st) // 6)
    fade_out = min(int(0.012 * SR), len(st) // 3)
    if fade_in > 1:
        ramp_in = np.linspace(0.0, 1.0, fade_in)[:, None]
        st[:fade_in] *= ramp_in
    if fade_out > 1:
        ramp_out = np.linspace(1.0, 0.0, fade_out)[:, None]
        st[-fade_out:] *= ramp_out

    peak = float(np.max(np.abs(st))) if len(st) > 0 else 0.0
    if peak > 1e-6:
        st = st * min(0.92 / peak, 1.8)
    st = np.clip(st, -0.96, 0.96)

    pcm = (st * 32767.0).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        wav_path = Path(tf.name)
    try:
        with wave.open(str(wav_path), "wb") as wf:
            wf.setnchannels(2)
            wf.setsampwidth(2)
            wf.setframerate(SR)
            wf.writeframes(pcm.tobytes())
        cmd = [
            str(FFMPEG), "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-c:a", "libvorbis", "-b:a", bitrate,
            str(out_path),
        ]
        subprocess.run(cmd, check=True)
    finally:
        if wav_path.exists():
            wav_path.unlink()


def env_ad(n: int, attack_s: float = 0.004, decay: float = 10.0) -> np.ndarray:
    t = np.linspace(0.0, n / SR, n, endpoint=False)
    att = np.minimum(1.0, t / max(1e-5, attack_s))
    return att * np.exp(-decay * t)


def fft_filter(sig: np.ndarray, low_hz: float = 0.0, high_hz: float = 20000.0, slope: float = 2.0) -> np.ndarray:
    """Zero-phase spectral shaping (clean LP/HP/BP without ringing clicks)."""
    n = len(sig)
    if n < 8:
        return sig
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    gain = np.ones_like(freqs)
    if low_hz > 1.0:
        gain *= 1.0 / (1.0 + (low_hz / np.maximum(freqs, 1.0)) ** (2.0 * slope))
    if high_hz < 19900.0:
        gain *= 1.0 / (1.0 + (freqs / max(1.0, high_hz)) ** (2.0 * slope))
    spec = np.fft.rfft(sig)
    return np.fft.irfft(spec * gain, n=n)


def pan_stereo(mono: np.ndarray, pan: float = 0.0) -> np.ndarray:
    """Constant-power stereo pan (-1.0 left .. +1.0 right)."""
    p = max(-1.0, min(1.0, pan))
    angle = (p + 1.0) * math.pi * 0.25
    return np.column_stack((mono * math.cos(angle), mono * math.sin(angle)))


def stereo_chorus_sweep(
    dur: float,
    f0: float,
    f1: float,
    kind: str = "saw",
    decay: float = 10.0,
    detune: float = 0.006,
    lp_hz: float = 16000.0,
    hp_hz: float = 20.0,
) -> np.ndarray:
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    env = env_ad(n, 0.003, decay)

    def _osc(mult: float) -> np.ndarray:
        freqs = (f0 * mult) * (((f1 * mult) / max(1.0, f0 * mult)) ** (t / max(1e-5, dur)))
        phase = 2.0 * math.pi * np.cumsum(freqs) / SR
        if kind == "sine":
            raw = np.sin(phase)
        elif kind == "tri":
            raw = 2.0 * np.abs(2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0) - 1.0
        elif kind == "saw":
            raw = 2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0
        elif kind == "pulse":
            raw = np.tanh(3.2 * np.sin(phase))
        else:
            raw = np.sign(np.sin(phase))
        shaped = fft_filter(raw * env, low_hz=hp_hz, high_hz=lp_hz, slope=2.0)
        return shaped

    l = _osc(1.0 - detune)
    r = _osc(1.0 + detune)
    return np.column_stack((l, r))


def fm_strike(
    dur: float,
    f_car0: float,
    f_car1: float,
    mod_ratio: float = 1.48,
    mod_index: float = 3.5,
    decay_car: float = 11.0,
    decay_mod: float = 24.0,
    detune: float = 0.004,
) -> np.ndarray:
    """Metallic/crystalline FM percussion strike in wide stereo."""
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    env_c = env_ad(n, 0.0015, decay_car)
    env_m = env_ad(n, 0.001, decay_mod)

    def _side(m: float) -> np.ndarray:
        fc = (f_car0 * m) * (((f_car1 * m) / max(1.0, f_car0 * m)) ** (t / max(1e-5, dur)))
        fm = fc * mod_ratio
        phase_m = 2.0 * math.pi * np.cumsum(fm) / SR
        phase_c = 2.0 * math.pi * np.cumsum(fc) / SR + (mod_index * env_m) * np.sin(phase_m)
        return np.sin(phase_c) * env_c

    return np.column_stack((_side(1.0 - detune), _side(1.0 + detune)))


def noise_shaped(
    dur: float,
    low_hz: float = 400.0,
    high_hz: float = 8000.0,
    decay: float = 16.0,
    attack_s: float = 0.002,
    seed: int = 42,
    width: float = 0.8,
) -> np.ndarray:
    """Stereo decorrelated filtered noise burst."""
    n = int(SR * dur)
    rng = np.random.default_rng(seed)
    nl = rng.uniform(-1.0, 1.0, n)
    nr = rng.uniform(-1.0, 1.0, n)
    env = env_ad(n, attack_s, decay)
    fl = fft_filter(nl, low_hz=low_hz, high_hz=high_hz, slope=1.8) * env
    fr = fft_filter(nr, low_hz=low_hz, high_hz=high_hz, slope=1.8) * env
    mid = 0.5 * (fl + fr)
    side = 0.5 * (fl - fr) * width
    return np.column_stack((mid + side, mid - side))


def add_early_room(sig: np.ndarray, tail_ms: float = 45.0, wet: float = 0.22) -> np.ndarray:
    """Add stereo early reflections and warm room air to prevent dry synthetic harshness."""
    st = to_stereo(sig)
    pad = int((tail_ms + 30.0) * 0.001 * SR)
    out = np.zeros((len(st) + pad, 2), dtype=np.float64)
    out[:len(st)] += st
    taps = [(11, 0.52, -0.45), (19, 0.36, 0.50), (29, 0.24, -0.35), (int(tail_ms), 0.16, 0.40)]
    for d_ms, amp, pan_bias in taps:
        d = int(d_ms * 0.001 * SR)
        g_l = wet * amp * (1.0 - 0.3 * pan_bias)
        g_r = wet * amp * (1.0 + 0.3 * pan_bias)
        end = min(len(out), d + len(st))
        cnt = end - d
        if cnt > 0:
            refl_l = fft_filter(st[:cnt, 1], low_hz=180.0, high_hz=6200.0, slope=1.2)
            refl_r = fft_filter(st[:cnt, 0], low_hz=180.0, high_hz=6200.0, slope=1.2)
            out[d:end, 0] += refl_l * g_l
            out[d:end, 1] += refl_r * g_r
    return out


def mix_layers(*items) -> np.ndarray:
    """Mix stereo arrays or (offset_sec, array) tuples."""
    normalized = []
    max_len = 1
    for item in items:
        if isinstance(item, tuple):
            off = max(0, int(round(item[0] * SR)))
            arr = to_stereo(item[1])
        else:
            off = 0
            arr = to_stereo(item)
        normalized.append((off, arr))
        max_len = max(max_len, off + len(arr))
    res = np.zeros((max_len, 2), dtype=np.float64)
    for off, arr in normalized:
        res[off:off + len(arr)] += arr
    return res


def saturate(sig: np.ndarray, drive: float = 1.6) -> np.ndarray:
    return np.tanh(sig * drive) / math.tanh(drive)


def chord_hit(
    freqs: list[float],
    dur: float,
    kind: str = "tri",
    decay: float = 7.5,
    stagger_s: float = 0.0,
    lp_hz: float = 9500.0,
) -> np.ndarray:
    layers = []
    for idx, f in enumerate(freqs):
        pan = -0.35 + 0.7 * (idx / max(1, len(freqs) - 1))
        tone = stereo_chorus_sweep(dur, f, f * 1.003, kind=kind, decay=decay, detune=0.005, lp_hz=lp_hz)
        tone = mix_layers(tone, 0.38 * fm_strike(dur, f, f, mod_ratio=2.0, mod_index=1.2, decay_car=decay * 1.15, decay_mod=decay * 2.0))
        mono_avg = 0.5 * (tone[:, 0] + tone[:, 1])
        panned = 0.65 * tone + 0.35 * pan_stereo(mono_avg, pan)
        layers.append((idx * stagger_s, panned))
    return mix_layers(*layers)


def gen_sfx() -> None:
    out = AUDIO / "sfx"

    # 1. sfx_slash: razor metallic blade slice + airy whoosh + crisp sub snap
    slash = add_early_room(saturate(mix_layers(
        0.58 * noise_shaped(0.15, low_hz=1400, high_hz=9200, decay=20.0, attack_s=0.004, seed=11),
        0.52 * fm_strike(0.16, 1380, 420, mod_ratio=1.63, mod_index=2.8, decay_car=17.0, decay_mod=30.0),
        0.34 * stereo_chorus_sweep(0.12, 240, 72, "sine", decay=26.0, detune=0.002, lp_hz=900),
    ), 1.4), tail_ms=34.0, wet=0.20)
    save_ogg(slash, out / "sfx_slash.ogg")

    # 2. sfx_heavy_cleave: giant greataxe / vibroblade shockwave
    cleave = add_early_room(saturate(mix_layers(
        0.65 * stereo_chorus_sweep(0.28, 180, 42, "sine", decay=11.0, detune=0.003, lp_hz=600),
        0.48 * stereo_chorus_sweep(0.24, 340, 88, "saw", decay=13.5, detune=0.010, lp_hz=3200),
        0.52 * noise_shaped(0.22, low_hz=550, high_hz=5400, decay=15.0, attack_s=0.006, seed=12),
        (0.015, 0.42 * fm_strike(0.24, 720, 260, mod_ratio=1.41, mod_index=3.2, decay_car=12.0, decay_mod=24.0)),
    ), 1.85), tail_ms=52.0, wet=0.26)
    save_ogg(cleave, out / "sfx_heavy_cleave.ogg")

    # 3. sfx_gun_shot: snappy kinetic pistol/rail crack + chamber kick
    gun = add_early_room(saturate(mix_layers(
        0.72 * stereo_chorus_sweep(0.12, 390, 52, "pulse", decay=28.0, detune=0.002, lp_hz=2800),
        0.62 * noise_shaped(0.11, low_hz=900, high_hz=11000, decay=34.0, attack_s=0.001, seed=13),
        0.38 * fm_strike(0.06, 2200, 680, mod_ratio=1.92, mod_index=2.2, decay_car=48.0, decay_mod=65.0),
    ), 1.9), tail_ms=38.0, wet=0.22)
    save_ogg(gun, out / "sfx_gun_shot.ogg")

    # 4. sfx_laser_zap: neon energy beam chirp + sci-fi FM harmonic zap
    laser = add_early_room(saturate(mix_layers(
        0.64 * stereo_chorus_sweep(0.18, 2250, 340, "saw", decay=16.0, detune=0.008, lp_hz=9000),
        0.45 * fm_strike(0.17, 1180, 290, mod_ratio=2.35, mod_index=3.6, decay_car=17.0, decay_mod=22.0),
        0.24 * noise_shaped(0.08, low_hz=2400, high_hz=10500, decay=28.0, seed=14),
    ), 1.4), tail_ms=40.0, wet=0.22)
    save_ogg(laser, out / "sfx_laser_zap.ogg")

    # 5. sfx_chain_lightning: multi-arc wide-panned plasma crackle
    lightning = add_early_room(saturate(mix_layers(
        0.58 * noise_shaped(0.22, low_hz=1800, high_hz=12500, decay=16.0, seed=15, width=1.0),
        0.42 * pan_stereo(fm_strike(0.14, 1950, 520, mod_ratio=2.7, mod_index=4.4, decay_car=22.0)[:, 0], -0.65),
        (0.036, 0.44 * pan_stereo(fm_strike(0.14, 2400, 680, mod_ratio=2.4, mod_index=4.0, decay_car=22.0)[:, 1], 0.70)),
        (0.072, 0.36 * stereo_chorus_sweep(0.16, 480, 140, "pulse", decay=14.0, detune=0.014, lp_hz=4200)),
    ), 1.7), tail_ms=48.0, wet=0.25)
    save_ogg(lightning, out / "sfx_chain_lightning.ogg")

    # 6. sfx_ice_cast: shimmering frost crystals + airy cold rush
    ice = add_early_room(mix_layers(
        0.42 * noise_shaped(0.22, low_hz=2800, high_hz=13000, decay=13.0, attack_s=0.010, seed=16),
        0.46 * fm_strike(0.24, 1760, 2100, mod_ratio=2.76, mod_index=2.4, decay_car=12.0, decay_mod=24.0),
        (0.032, 0.40 * fm_strike(0.21, 2637, 2950, mod_ratio=1.52, mod_index=1.9, decay_car=13.0, decay_mod=26.0)),
    ), tail_ms=55.0, wet=0.30)
    save_ogg(ice, out / "sfx_ice_cast.ogg")

    # 7. sfx_mortar_boom: massive abyssal explosion with sub drop + rumble + debris
    boom = add_early_room(saturate(mix_layers(
        0.92 * stereo_chorus_sweep(0.46, 138, 28, "sine", decay=6.8, detune=0.002, lp_hz=450),
        0.55 * stereo_chorus_sweep(0.28, 220, 48, "pulse", decay=12.0, detune=0.006, lp_hz=1200),
        0.72 * noise_shaped(0.44, low_hz=60, high_hz=1600, decay=7.5, attack_s=0.002, seed=17),
        0.42 * noise_shaped(0.24, low_hz=1800, high_hz=7200, decay=18.0, attack_s=0.001, seed=18),
    ), 2.1), tail_ms=70.0, wet=0.28)
    save_ogg(boom, out / "sfx_mortar_boom.ogg")

    # 8. sfx_hit_enemy: compact round tactile punch (non-harsh on high fire rate)
    hit = saturate(mix_layers(
        0.70 * stereo_chorus_sweep(0.085, 250, 74, "sine", decay=34.0, detune=0.002, lp_hz=1400),
        0.38 * noise_shaped(0.055, low_hz=900, high_hz=4200, decay=46.0, attack_s=0.001, seed=19),
    ), 1.45)
    save_ogg(hit, out / "sfx_hit_enemy.ogg")

    # 9. sfx_crit_hit: decisive lethal impact + bright steel crit ring
    crit = add_early_room(saturate(mix_layers(
        0.66 * stereo_chorus_sweep(0.14, 290, 68, "pulse", decay=22.0, detune=0.004, lp_hz=2600),
        0.58 * fm_strike(0.19, 1046, 1568, mod_ratio=1.50, mod_index=2.6, decay_car=15.0, decay_mod=28.0),
        0.34 * noise_shaped(0.09, low_hz=2200, high_hz=9800, decay=30.0, seed=20),
    ), 1.6), tail_ms=42.0, wet=0.24)
    save_ogg(crit, out / "sfx_crit_hit.ogg")

    # 10. sfx_armor_break: heavy plate crack + shattering shards across stereo field
    armor = add_early_room(saturate(mix_layers(
        0.65 * stereo_chorus_sweep(0.20, 210, 48, "pulse", decay=14.0, detune=0.005, lp_hz=1800),
        0.48 * pan_stereo(fm_strike(0.22, 1320, 620, mod_ratio=1.83, mod_index=4.2, decay_car=12.0)[:, 0], -0.55),
        (0.025, 0.45 * pan_stereo(fm_strike(0.20, 1890, 910, mod_ratio=2.14, mod_index=3.8, decay_car=13.0)[:, 1], 0.60)),
        (0.052, 0.36 * fm_strike(0.18, 2640, 1480, mod_ratio=1.62, mod_index=3.0, decay_car=15.0)),
        0.44 * noise_shaped(0.14, low_hz=1400, high_hz=10000, decay=22.0, seed=21),
    ), 1.7), tail_ms=55.0, wet=0.26)
    save_ogg(armor, out / "sfx_armor_break.ogg")

    # 11. sfx_enemy_die: snappy abyssal pop + dark vapor puff
    die = add_early_room(saturate(mix_layers(
        0.56 * stereo_chorus_sweep(0.14, 290, 58, "sine", decay=20.0, detune=0.004, lp_hz=1800),
        0.42 * noise_shaped(0.13, low_hz=700, high_hz=4500, decay=24.0, seed=22),
        0.24 * fm_strike(0.10, 580, 190, mod_ratio=1.41, mod_index=2.2, decay_car=26.0),
    ), 1.4), tail_ms=32.0, wet=0.18)
    save_ogg(die, out / "sfx_enemy_die.ogg")

    # 12. sfx_player_hurt: visceral heavy warning crunch + tense dissonant throb
    hurt = add_early_room(saturate(mix_layers(
        0.78 * stereo_chorus_sweep(0.24, 175, 42, "pulse", decay=12.0, detune=0.005, lp_hz=1600),
        0.48 * stereo_chorus_sweep(0.22, 235, 118, "saw", decay=13.0, detune=0.015, lp_hz=2400),
        0.40 * noise_shaped(0.16, low_hz=350, high_hz=3600, decay=18.0, seed=23),
    ), 1.9), tail_ms=42.0, wet=0.20)
    save_ogg(hurt, out / "sfx_player_hurt.ogg")

    # 13. sfx_dash: wide stereo blood-step phase whoosh
    dash = add_early_room(mix_layers(
        0.58 * noise_shaped(0.20, low_hz=500, high_hz=7200, decay=15.0, attack_s=0.012, seed=24, width=1.0),
        0.54 * stereo_chorus_sweep(0.19, 320, 960, "sine", decay=15.0, detune=0.008, lp_hz=3500),
        0.34 * stereo_chorus_sweep(0.12, 190, 68, "sine", decay=22.0, detune=0.003, lp_hz=800),
    ), tail_ms=45.0, wet=0.24)
    save_ogg(dash, out / "sfx_dash.ogg")

    # 14. sfx_pickup_crystal: bright glassy twin-sparkle
    crystal = add_early_room(mix_layers(
        0.52 * fm_strike(0.10, 1046.5, 1055.0, mod_ratio=2.0, mod_index=1.1, decay_car=24.0, decay_mod=36.0),
        (0.024, 0.56 * fm_strike(0.11, 1567.98, 1582.0, mod_ratio=2.0, mod_index=1.0, decay_car=22.0, decay_mod=34.0)),
    ), tail_ms=34.0, wet=0.22)
    save_ogg(crystal, out / "sfx_pickup_crystal.ogg")

    # 15. sfx_pickup_heal: warm glowing restorative chime
    heal = add_early_room(chord_hit([523.25, 659.25, 783.99, 1046.5], 0.25, kind="sine", decay=11.0, stagger_s=0.025, lp_hz=8000), tail_ms=52.0, wet=0.28)
    save_ogg(heal, out / "sfx_pickup_heal.ogg")

    # 16. sfx_pickup_chest: sparkling elite reward arpeggio
    chest = add_early_room(chord_hit([523.25, 659.25, 783.99, 987.77, 1318.5], 0.28, kind="tri", decay=8.5, stagger_s=0.062, lp_hz=10500), tail_ms=70.0, wet=0.32)
    save_ogg(chest, out / "sfx_pickup_chest.ogg")

    # 17. sfx_level_up: soaring radiant power-up cascade
    lvl = add_early_room(mix_layers(
        0.48 * stereo_chorus_sweep(0.24, 220, 440, "sine", decay=10.0, detune=0.005, lp_hz=2000),
        0.75 * chord_hit([440.0, 554.37, 659.25, 880.0, 1108.73], 0.28, kind="tri", decay=8.0, stagger_s=0.055, lp_hz=11000),
    ), tail_ms=75.0, wet=0.32)
    save_ogg(lvl, out / "sfx_level_up.ogg")

    # 18. sfx_wave_start: cyber arena horn + deep sub punch
    wstart = add_early_room(saturate(mix_layers(
        0.65 * stereo_chorus_sweep(0.24, 120, 44, "sine", decay=12.0, detune=0.003, lp_hz=500),
        0.58 * stereo_chorus_sweep(0.36, 146.83, 293.66, "saw", decay=6.5, detune=0.010, lp_hz=3800),
        0.38 * stereo_chorus_sweep(0.36, 293.66, 587.33, "tri", decay=7.0, detune=0.008, lp_hz=6400),
        0.30 * noise_shaped(0.14, low_hz=1200, high_hz=8500, decay=18.0, seed=25),
    ), 1.45), tail_ms=65.0, wet=0.28)
    save_ogg(wstart, out / "sfx_wave_start.ogg")

    # 19. sfx_wave_clear: bright resolving victory chord
    wclr = add_early_room(chord_hit([587.33, 739.99, 880.0, 1174.66], 0.34, kind="sine", decay=7.0, stagger_s=0.058, lp_hz=9500), tail_ms=72.0, wet=0.32)
    save_ogg(wclr, out / "sfx_wave_clear.ogg")

    # 20. sfx_buy_merge: anvil forge ping + bright coin chime
    merge = add_early_room(mix_layers(
        0.48 * fm_strike(0.16, 880.0, 885.0, mod_ratio=1.50, mod_index=2.2, decay_car=17.0, decay_mod=28.0),
        (0.045, 0.56 * fm_strike(0.18, 1318.5, 1325.0, mod_ratio=2.0, mod_index=1.3, decay_car=15.0, decay_mod=25.0)),
    ), tail_ms=48.0, wet=0.26)
    save_ogg(merge, out / "sfx_buy_merge.ogg")

    # 21. sfx_reroll: crisp double mechanical card flip
    reroll = add_early_room(mix_layers(
        0.48 * fm_strike(0.06, 780, 520, mod_ratio=1.6, mod_index=1.6, decay_car=35.0),
        0.32 * noise_shaped(0.05, low_hz=1800, high_hz=8000, decay=42.0, seed=26),
        (0.045, 0.52 * fm_strike(0.08, 1040, 1360, mod_ratio=1.5, mod_index=1.4, decay_car=28.0)),
    ), tail_ms=28.0, wet=0.18)
    save_ogg(reroll, out / "sfx_reroll.ogg")

    # 22. sfx_pact_sign: dark ritual bronze gong + abyssal bass swell
    pact = add_early_room(saturate(mix_layers(
        0.65 * stereo_chorus_sweep(0.68, 98.0, 73.4, "sine", decay=3.8, detune=0.004, lp_hz=450),
        0.58 * fm_strike(0.72, 146.83, 144.0, mod_ratio=1.47, mod_index=3.4, decay_car=4.2, decay_mod=11.0),
        (0.020, 0.36 * fm_strike(0.55, 293.66, 290.0, mod_ratio=2.13, mod_index=2.4, decay_car=5.5, decay_mod=15.0)),
        0.24 * noise_shaped(0.35, low_hz=400, high_hz=2800, decay=8.5, attack_s=0.02, seed=27),
    ), 1.4), tail_ms=95.0, wet=0.35)
    save_ogg(pact, out / "sfx_pact_sign.ogg")

    # 23. sfx_awakening: mythic red awakening super-chord & crystalline burst
    awk = add_early_room(saturate(mix_layers(
        0.46 * stereo_chorus_sweep(0.50, 130.81, 261.63, "saw", decay=4.5, detune=0.012, lp_hz=4800),
        0.82 * chord_hit([523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98], 0.42, kind="tri", decay=5.5, stagger_s=0.052, lp_hz=12000),
        0.30 * noise_shaped(0.36, low_hz=3000, high_hz=12000, decay=9.0, attack_s=0.04, seed=28),
    ), 1.35), tail_ms=95.0, wet=0.35)
    save_ogg(awk, out / "sfx_awakening.ogg")

    # 24. sfx_boss_warn: ominous dual-pulse cyber-brass klaxon + sub thump
    pulse1 = mix_layers(
        0.58 * stereo_chorus_sweep(0.30, 260, 440, "saw", decay=5.5, detune=0.014, lp_hz=3200),
        0.42 * stereo_chorus_sweep(0.28, 130, 58, "sine", decay=8.0, detune=0.003, lp_hz=500),
    )
    pulse2 = mix_layers(
        0.62 * stereo_chorus_sweep(0.36, 440, 220, "saw", decay=4.8, detune=0.014, lp_hz=3000),
        0.44 * stereo_chorus_sweep(0.32, 110, 42, "sine", decay=7.5, detune=0.003, lp_hz=450),
    )
    boss_warn = add_early_room(saturate(mix_layers(pulse1, (0.28, pulse2)), 1.55), tail_ms=75.0, wet=0.30)
    save_ogg(boss_warn, out / "sfx_boss_warn.ogg")

    # 25. sfx_ui_click: clean damped mobile glass/wood tap (zero harsh beep)
    ui_click = mix_layers(
        0.58 * stereo_chorus_sweep(0.055, 860, 390, "sine", decay=52.0, detune=0.002, lp_hz=2400),
        0.35 * fm_strike(0.032, 1950, 1200, mod_ratio=1.5, mod_index=1.1, decay_car=75.0, decay_mod=90.0),
    )
    save_ogg(ui_click, out / "sfx_ui_click.ogg")

    # 26. sfx_victory: grand heroic brass & chime finale
    victory = add_early_room(saturate(mix_layers(
        0.85 * chord_hit([523.25, 659.25, 783.99, 1046.5], 0.42, kind="tri", decay=5.5, stagger_s=0.075, lp_hz=11000),
        (0.34, 0.90 * chord_hit([523.25, 783.99, 1046.5, 1318.5, 1567.98], 0.56, kind="sine", decay=4.2, stagger_s=0.03, lp_hz=12000)),
        (0.34, 0.35 * stereo_chorus_sweep(0.45, 130.81, 130.81, "saw", decay=5.0, detune=0.009, lp_hz=2200)),
    ), 1.3), tail_ms=95.0, wet=0.35)
    save_ogg(victory, out / "sfx_victory.ogg")

    # 27. sfx_defeat: dark somber descending minor brass
    defeat = add_early_room(saturate(mix_layers(
        0.72 * chord_hit([392.0, 349.23, 311.13, 261.63], 0.36, kind="saw", decay=5.2, stagger_s=0.14, lp_hz=2400),
        (0.42, 0.55 * stereo_chorus_sweep(0.42, 98.0, 44.0, "sine", decay=4.5, detune=0.004, lp_hz=420)),
    ), 1.35), tail_ms=85.0, wet=0.30)
    save_ogg(defeat, out / "sfx_defeat.ogg")


def gen_bgm() -> None:
    out = AUDIO / "bgm"

    # Once the v01 AI soundtrack masters are archived under raw_audio/, BGM is
    # owned by the import_bgm.py mastering pipeline; do not overwrite the
    # finished looping tracks with the old short procedural placeholders.
    raw_dir = ROOT / "raw_audio"
    if raw_dir.exists() and list(raw_dir.glob("bgm_arena_soundtrack_loop_*_v01.wav")):
        print("[SKIP] v01 BGM masters found in raw_audio/; procedural placeholder BGM retained (managed by tools/import_bgm.py).")
        return

    def make_loop(bpm: float, bars: int, bass_pattern: list[int], arp_pattern: list[int], intensity: float) -> np.ndarray:
        step_dur = 60.0 / bpm / 4.0
        total_steps = bars * 16
        total_n = int(round(total_steps * step_dur * SR))
        buf = np.zeros((total_n, 2), dtype=np.float64)

        def midi_to_hz(m: int) -> float:
            return 440.0 * (2.0 ** ((m - 69) / 12.0))

        for step in range(total_steps):
            s_idx = int(round(step * step_dur * SR))
            if step % 2 == 0:
                note = bass_pattern[(step // 2) % len(bass_pattern)]
                if note > 0:
                    dur = step_dur * 1.9
                    n = min(int(dur * SR), total_n - s_idx)
                    t = np.linspace(0.0, n / SR, n, endpoint=False)
                    hz = midi_to_hz(note)
                    sig = 0.6 * np.sin(2 * math.pi * hz * t) + 0.35 * np.tanh(1.8 * np.sin(2 * math.pi * hz * t))
                    env = np.minimum(1.0, t / 0.008) * np.exp(-5.0 * t)
                    mono = 0.34 * sig * env
                    buf[s_idx:s_idx + n] += np.column_stack((mono, mono))

            anote = arp_pattern[step % len(arp_pattern)]
            if anote > 0:
                dur = step_dur * 1.25
                n = min(int(dur * SR), total_n - s_idx)
                t = np.linspace(0.0, n / SR, n, endpoint=False)
                hz = midi_to_hz(anote)
                sig_l = 2.0 * np.abs(2.0 * ((hz * 0.996 * t) % 1.0) - 1.0) - 1.0
                sig_r = 2.0 * np.abs(2.0 * ((hz * 1.004 * t) % 1.0) - 1.0) - 1.0
                env = np.minimum(1.0, t / 0.005) * np.exp(-9.0 * t)
                buf[s_idx:s_idx + n] += (0.14 + 0.08 * intensity) * np.column_stack((sig_l * env, sig_r * env))

            if intensity > 0.2 and step % 4 == 0:
                n = min(int(0.14 * SR), total_n - s_idx)
                t = np.linspace(0.0, n / SR, n, endpoint=False)
                freqs = 125.0 * ((42.0 / 125.0) ** (t / 0.14))
                phase = 2.0 * math.pi * np.cumsum(freqs) / SR
                kick = (0.38 * intensity) * np.sin(phase) * np.exp(-18.0 * t)
                buf[s_idx:s_idx + n] += np.column_stack((kick, kick))

            if intensity > 0.4 and step % 8 == 4:
                n = min(int(0.10 * SR), total_n - s_idx)
                rng = np.random.default_rng(100 + step)
                sn = (0.18 * intensity) * rng.uniform(-1.0, 1.0, n) * np.exp(-26.0 * np.linspace(0.0, n / SR, n, endpoint=False))
                buf[s_idx:s_idx + n] += np.column_stack((sn, sn))
            elif intensity > 0.6 and step % 2 == 1:
                n = min(int(0.04 * SR), total_n - s_idx)
                rng = np.random.default_rng(300 + step)
                hat = 0.08 * rng.uniform(-1.0, 1.0, n) * np.exp(-55.0 * np.linspace(0.0, n / SR, n, endpoint=False))
                buf[s_idx:s_idx + n] += np.column_stack((hat, hat))

        buf = np.tanh(buf * 1.15) * 0.72
        fade = int(0.015 * SR)
        buf[:fade] *= np.linspace(0.0, 1.0, fade)[:, None]
        buf[-fade:] *= np.linspace(1.0, 0.0, fade)[:, None]
        return buf

    save_ogg(make_loop(92.0, 4, [38, 38, 41, 41, 45, 45, 43, 40], [62, 65, 69, 0, 62, 69, 72, 69, 60, 64, 67, 0, 60, 67, 72, 67], 0.15), out / "bgm_sanctuary.ogg", bitrate="128k")
    save_ogg(make_loop(132.0, 8, [38, 38, 38, 50, 41, 41, 43, 45], [62, 69, 65, 69, 74, 69, 65, 69, 60, 67, 64, 67, 72, 67, 64, 67], 0.75), out / "bgm_combat.ogg", bitrate="128k")
    save_ogg(make_loop(152.0, 8, [38, 50, 38, 50, 41, 53, 40, 52], [62, 74, 65, 74, 69, 74, 70, 74, 62, 74, 67, 74, 72, 70, 69, 65], 1.0), out / "bgm_boss.ogg", bitrate="128k")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate procedural audio assets for Pact Arena.")
    parser.add_argument("--sfx-only", action="store_true", help="Regenerate only the 27 SFX OGG files.")
    parser.add_argument("--bgm-only", action="store_true", help="Regenerate only the 3 BGM OGG files.")
    args = parser.parse_args()

    ensure_dirs()
    if not args.bgm_only:
        gen_sfx()
    if not args.sfx_only:
        gen_bgm()
    print("Audio generation complete in", AUDIO)
