# 產生 sfx/ 底下的內建音效（sfxr 風格的程式合成，產物是 CC0）。
# 用法：在專案根目錄執行 python tools/generate_sfx.py，只用 Python 標準函式庫。
# 這個資料夾有 .gdignore，Godot 不會匯入，學員在編輯器裡看不到。

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "sfx"


# 方波（duty 是高電位佔一個週期的比例）
def square(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0


# 鋸齒波
def saw(phase):
    return 2.0 * (phase % 1.0) - 1.0


# 依頻率曲線 freq(t) 與波形 osc 產生樣本，振幅包絡 env(t)
def tone(duration, freq, osc, env):
    samples = []
    phase = 0.0
    n = int(duration * RATE)
    for i in range(n):
        t = i / n
        phase += freq(t) / RATE
        samples.append(osc(phase) * env(t))
    return samples


# 白噪音經過一階低通，cutoff(t) 介於 0～1，越小越悶
def noise(duration, cutoff, env, seed):
    rng = random.Random(seed)
    samples = []
    last = 0.0
    n = int(duration * RATE)
    for i in range(n):
        t = i / n
        last += (rng.uniform(-1.0, 1.0) - last) * cutoff(t)
        samples.append(last * env(t))
    return samples


# 兩段聲音相加（長度不同時短的補零）
def mix(a, b, gain_b=1.0):
    n = max(len(a), len(b))
    a = a + [0.0] * (n - len(a))
    b = b + [0.0] * (n - len(b))
    return [x + y * gain_b for x, y in zip(a, b)]


# 指數衰減包絡，開頭 3 毫秒淡入避免爆音
def decay(speed):
    def env(t):
        attack = min(1.0, t * 100.0)
        return attack * math.exp(-speed * t) * (1.0 - t) ** 0.3
    return env


# 正規化到 peak 音量後寫成 16-bit 單聲道 wav
def save(name, samples, peak=0.7):
    top = max(abs(s) for s in samples) or 1.0
    data = b"".join(struct.pack("<h", int(s / top * peak * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    print(f"{name}: {len(data) // 1024} KB")


def main():
    OUT.mkdir(exist_ok=True)
    # 跳躍：方波往上滑
    save("jump.wav", tone(0.18, lambda t: 280 + 480 * t, lambda p: square(p, 0.4), decay(3.0)))
    # 落地：低沉的噗
    save("land.wav", mix(
        noise(0.12, lambda t: 0.15 - 0.1 * t, decay(6.0), 1),
        tone(0.12, lambda t: 140 - 80 * t, lambda p: math.sin(p * math.tau), decay(5.0)), 0.8))
    # 受傷：方波往下滑，混一點雜音
    save("hurt.wav", mix(
        tone(0.25, lambda t: 520 - 380 * t, lambda p: square(p, 0.5), decay(2.5)),
        noise(0.25, lambda t: 0.5, decay(4.0), 2), 0.35))
    # 爆炸：越來越悶的雜音
    save("explosion.wav", noise(0.6, lambda t: 0.6 - 0.55 * t, decay(4.0), 3))
    # 撿東西：兩個音往上跳
    save("pickup.wav", tone(0.15, lambda t: 660 if t < 0.4 else 990, lambda p: square(p, 0.5), decay(2.0)))
    # 金幣：經典的 B5 → E6
    save("coin.wav", tone(0.32, lambda t: 988 if t < 0.18 else 1319, lambda p: square(p, 0.5), decay(3.0)))
    # 雷射：鋸齒波快速往下滑
    save("laser.wav", tone(0.2, lambda t: 1300 * (1.0 - t) ** 2 + 180, saw, decay(4.0)), peak=0.55)
    # 嗶：短短的方波
    save("beep.wav", tone(0.1, lambda t: 880, lambda p: square(p, 0.5), decay(1.0)), peak=0.5)


if __name__ == "__main__":
    main()
