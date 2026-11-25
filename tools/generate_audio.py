"""
Procedural dark-cyber roguelite audio generator for Pact Arena (血契竞技场).
Synthesizes crisp layered SFX and seamless loopable OGG BGM tracks using NumPy + FFmpeg.
"""
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


def ensure_dirs():
    (AUDIO / "sfx").mkdir(parents=True, exist_ok=True)
    (AUDIO / "bgm").mkdir(parents=True, exist_ok=True)


def save_ogg(samples: np.ndarray, out_path: Path, bitrate: str = "112k"):
    samples = np.clip(samples, -0.96, 0.96)
    pcm = (samples * 32767.0).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        wav_path = Path(tf.name)
    try:
        with wave.open(str(wav_path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(SR)
            wf.writeframes(pcm.tobytes())
        cmd = [
            str(FFMPEG), "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-c:a", "libvorbis", "-b:a", bitrate,
            str(out_path)
        ]
        subprocess.run(cmd, check=True)
    finally:
        if wav_path.exists():
            wav_path.unlink()


def env_exp(n: int, attack_s: float = 0.004, decay: float = 10.0) -> np.ndarray:
    t = np.linspace(0.0, n / SR, n, endpoint=False)
    att = np.minimum(1.0, t / max(1e-5, attack_s))
    return att * np.exp(-decay * t)


def synth_sweep(dur: float, f0: float, f1: float, kind: str = "sine", decay: float = 10.0) -> np.ndarray:
    n = int(SR * dur)
    t = np.linspace(0.0, dur, n, endpoint=False)
    freqs = f0 * ((f1 / max(1.0, f0)) ** (t / max(1e-5, dur)))
    phase = 2.0 * math.pi * np.cumsum(freqs) / SR
    if kind == "sine":
        sig = np.sin(phase)
    elif kind == "tri":
        sig = 2.0 * np.abs(2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0) - 1.0
    elif kind == "saw":
        sig = 2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0
    else:
        sig = np.sign(np.sin(phase))
    return sig * env_exp(n, 0.003, decay)


def noise_burst(dur: float, decay: float = 14.0, hp_alpha: float = 0.0) -> np.ndarray:
    n = int(SR * dur)
    rng = np.random.default_rng(42)
    z = rng.uniform(-1.0, 1.0, n)
    if hp_alpha > 0.0:
        out = np.zeros_like(z)
        for i in range(1, n):
            out[i] = hp_alpha * (out[i - 1] + z[i] - z[i - 1])
        z = out
    return z * env_exp(n, 0.002, decay)


def mix(*arrs: np.ndarray) -> np.ndarray:
    max_len = max(len(a) for a in arrs)
    res = np.zeros(max_len, dtype=np.float64)
    for a in arrs:
        res[:len(a)] += a
    return res


def gen_sfx():
    out = AUDIO / "sfx"
    # Combat & Weapons
    save_ogg(mix(0.55 * noise_burst(0.14, 24.0, 0.85), 0.45 * synth_sweep(0.14, 620, 190, "saw", 18.0)), out / "sfx_slash.ogg")
    save_ogg(mix(0.65 * synth_sweep(0.24, 240, 62, "saw", 11.0), 0.45 * noise_burst(0.22, 16.0, 0.65)), out / "sfx_heavy_cleave.ogg")
    save_ogg(mix(0.60 * synth_sweep(0.11, 900, 180, "square", 26.0), 0.45 * noise_burst(0.09, 32.0, 0.8)), out / "sfx_gun_shot.ogg")
    save_ogg(mix(0.70 * synth_sweep(0.16, 1500, 420, "saw", 16.0), 0.25 * synth_sweep(0.16, 2200, 750, "sine", 20.0)), out / "sfx_laser_zap.ogg")
    save_ogg(mix(0.55 * synth_sweep(0.20, 1900, 520, "square", 15.0), 0.45 * noise_burst(0.18, 18.0, 0.92)), out / "sfx_chain_lightning.ogg")
    save_ogg(mix(0.60 * synth_sweep(0.18, 1100, 1750, "tri", 14.0), 0.35 * noise_burst(0.16, 20.0, 0.9)), out / "sfx_ice_cast.ogg")
    save_ogg(mix(0.85 * synth_sweep(0.42, 145, 36, "sine", 6.5), 0.55 * noise_burst(0.38, 8.0, 0.2)), out / "sfx_mortar_boom.ogg")

    # Hits & Kills
    save_ogg(mix(0.55 * synth_sweep(0.08, 320, 110, "tri", 30.0), 0.35 * noise_burst(0.06, 40.0, 0.7)), out / "sfx_hit_enemy.ogg")
    save_ogg(mix(0.65 * synth_sweep(0.16, 780, 1380, "tri", 18.0), 0.45 * synth_sweep(0.14, 420, 120, "saw", 16.0)), out / "sfx_crit_hit.ogg")
    save_ogg(mix(0.60 * synth_sweep(0.22, 540, 160, "square", 13.0), 0.45 * synth_sweep(0.22, 1080, 320, "tri", 12.0)), out / "sfx_armor_break.ogg")
    save_ogg(mix(0.50 * synth_sweep(0.14, 240, 70, "sine", 18.0), 0.35 * noise_burst(0.12, 22.0, 0.7)), out / "sfx_enemy_die.ogg")
    save_ogg(mix(0.75 * synth_sweep(0.24, 190, 58, "saw", 11.0), 0.35 * noise_burst(0.18, 15.0, 0.5)), out / "sfx_player_hurt.ogg")

    # Movement & Pickups
    save_ogg(mix(0.55 * synth_sweep(0.18, 380, 980, "sine", 14.0), 0.40 * noise_burst(0.16, 16.0, 0.88)), out / "sfx_dash.ogg")
    save_ogg(0.60 * synth_sweep(0.10, 880, 1320, "sine", 24.0), out / "sfx_pickup_crystal.ogg")
    save_ogg(mix(0.55 * synth_sweep(0.22, 523.25, 784.0, "sine", 11.0), 0.30 * synth_sweep(0.22, 659.25, 1046.5, "tri", 11.0)), out / "sfx_pickup_heal.ogg")
    # Chest chime (C-E-G-B)
    notes = [523.25, 659.25, 783.99, 1046.5]
    parts = [synth_sweep(0.13, f, f * 1.01, "tri", 10.0) * 0.6 for f in notes]
    save_ogg(np.concatenate(parts), out / "sfx_pickup_chest.ogg")

    # Progression & UI
    lvl = np.concatenate([synth_sweep(0.11, f, f, "tri", 8.0) * 0.65 for f in [440, 554.37, 659.25, 880]])
    save_ogg(lvl, out / "sfx_level_up.ogg")
    save_ogg(mix(0.65 * synth_sweep(0.32, 220, 440, "saw", 7.0), 0.35 * synth_sweep(0.32, 440, 880, "tri", 7.0)), out / "sfx_wave_start.ogg")
    wclr = np.concatenate([synth_sweep(0.12, f, f, "sine", 9.0) * 0.65 for f in [587.33, 739.99, 880, 1174.66]])
    save_ogg(wclr, out / "sfx_wave_clear.ogg")
    save_ogg(mix(0.65 * synth_sweep(0.16, 480, 960, "tri", 15.0), 0.35 * synth_sweep(0.16, 720, 1440, "sine", 15.0)), out / "sfx_buy_merge.ogg")
    save_ogg(0.55 * synth_sweep(0.10, 660, 440, "tri", 22.0), out / "sfx_reroll.ogg")
    # Deep ritual gong for Blood Pact
    save_ogg(mix(0.75 * synth_sweep(0.65, 110, 82, "saw", 4.0), 0.50 * synth_sweep(0.65, 220, 164, "sine", 4.5)), out / "sfx_pact_sign.ogg")
    # Awakening shimmer
    awk = np.concatenate([synth_sweep(0.15, f, f * 1.02, "saw", 6.5) * 0.55 for f in [523.25, 659.25, 783.99, 1046.5, 1318.5]])
    save_ogg(awk, out / "sfx_awakening.ogg")
    # Boss warning siren
    siren = np.concatenate([synth_sweep(0.28, 330, 520, "saw", 5.0) * 0.65, synth_sweep(0.28, 520, 290, "saw", 5.0) * 0.65])
    save_ogg(siren, out / "sfx_boss_warn.ogg")
    save_ogg(0.45 * synth_sweep(0.055, 760, 520, "sine", 40.0), out / "sfx_ui_click.ogg")
    save_ogg(np.concatenate([synth_sweep(0.16, f, f, "tri", 6.0) * 0.65 for f in [523.25, 659.25, 783.99, 1046.5, 1567.98]]), out / "sfx_victory.ogg")
    save_ogg(np.concatenate([synth_sweep(0.20, f, f * 0.94, "saw", 5.5) * 0.6 for f in [392.0, 349.23, 311.13, 261.63]]), out / "sfx_defeat.ogg")


def gen_bgm():
    out = AUDIO / "bgm"

    def make_loop(bpm: float, bars: int, bass_pattern: list[int], arp_pattern: list[int], intensity: float) -> np.ndarray:
        step_dur = 60.0 / bpm / 4.0  # 16th note
        total_steps = bars * 16
        total_n = int(round(total_steps * step_dur * SR))
        buf = np.zeros(total_n, dtype=np.float64)

        def midi_to_hz(m):
            return 440.0 * (2.0 ** ((m - 69) / 12.0))

        for step in range(total_steps):
            s_idx = int(round(step * step_dur * SR))
            # Bass on 8th notes
            if step % 2 == 0:
                note = bass_pattern[(step // 2) % len(bass_pattern)]
                if note > 0:
                    dur = step_dur * 1.9
                    n = min(int(dur * SR), total_n - s_idx)
                    t = np.linspace(0.0, n / SR, n, endpoint=False)
                    hz = midi_to_hz(note)
                    sig = 0.6 * np.sin(2 * math.pi * hz * t) + 0.35 * np.tanh(1.8 * np.sin(2 * math.pi * hz * t))
                    env = np.minimum(1.0, t / 0.008) * np.exp(-5.0 * t)
                    buf[s_idx:s_idx + n] += 0.34 * sig * env

            # Arpeggio lead
            anote = arp_pattern[step % len(arp_pattern)]
            if anote > 0:
                dur = step_dur * 1.25
                n = min(int(dur * SR), total_n - s_idx)
                t = np.linspace(0.0, n / SR, n, endpoint=False)
                hz = midi_to_hz(anote)
                sig = 2.0 * np.abs(2.0 * ((hz * t) % 1.0) - 1.0) - 1.0
                env = np.minimum(1.0, t / 0.005) * np.exp(-9.0 * t)
                buf[s_idx:s_idx + n] += (0.14 + 0.08 * intensity) * sig * env

            # Kick drum on beats
            if intensity > 0.2 and step % 4 == 0:
                n = min(int(0.14 * SR), total_n - s_idx)
                t = np.linspace(0.0, n / SR, n, endpoint=False)
                freqs = 125.0 * ((42.0 / 125.0) ** (t / 0.14))
                phase = 2.0 * math.pi * np.cumsum(freqs) / SR
                kick = np.sin(phase) * np.exp(-18.0 * t)
                buf[s_idx:s_idx + n] += (0.38 * intensity) * kick

            # Snare/Hat
            if intensity > 0.4 and step % 8 == 4:
                n = min(int(0.10 * SR), total_n - s_idx)
                rng = np.random.default_rng(100 + step)
                sn = rng.uniform(-1.0, 1.0, n) * np.exp(-26.0 * np.linspace(0.0, n / SR, n, endpoint=False))
                buf[s_idx:s_idx + n] += (0.18 * intensity) * sn
            elif intensity > 0.6 and step % 2 == 1:
                n = min(int(0.04 * SR), total_n - s_idx)
                rng = np.random.default_rng(300 + step)
                hat = rng.uniform(-1.0, 1.0, n) * np.exp(-55.0 * np.linspace(0.0, n / SR, n, endpoint=False))
                buf[s_idx:s_idx + n] += 0.08 * hat

        # Soft master limiter + short edge crossfade for seamless loop
        buf = np.tanh(buf * 1.15) * 0.72
        fade = int(0.015 * SR)
        buf[:fade] *= np.linspace(0.0, 1.0, fade)
        buf[-fade:] *= np.linspace(1.0, 0.0, fade)
        return buf

    # D minor dark sanctuary (92 BPM)
    save_ogg(
        make_loop(
            92.0, 4,
            [38, 38, 41, 41, 45, 45, 43, 40],
            [62, 65, 69, 0, 62, 69, 72, 69, 60, 64, 67, 0, 60, 67, 72, 67],
            0.15,
        ),
        out / "bgm_sanctuary.ogg",
        bitrate="128k",
    )
    # Combat pulse (132 BPM)
    save_ogg(
        make_loop(
            132.0, 8,
            [38, 38, 38, 50, 41, 41, 43, 45],
            [62, 69, 65, 69, 74, 69, 65, 69, 60, 67, 64, 67, 72, 67, 64, 67],
            0.75,
        ),
        out / "bgm_combat.ogg",
        bitrate="128k",
    )
    # Boss intense overdrive (152 BPM)
    save_ogg(
        make_loop(
            152.0, 8,
            [38, 50, 38, 50, 41, 53, 40, 52],
            [62, 74, 65, 74, 69, 74, 70, 74, 62, 74, 67, 74, 72, 70, 69, 65],
            1.0,
        ),
        out / "bgm_boss.ogg",
        bitrate="128k",
    )


if __name__ == "__main__":
    ensure_dirs()
    gen_sfx()
    gen_bgm()
    print("All audio assets generated successfully in", AUDIO)
