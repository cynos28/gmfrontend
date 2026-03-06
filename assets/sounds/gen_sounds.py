import wave, struct, math, os

def write_wav(path, samples, rate=22050):
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(b''.join(struct.pack('<h', min(32767, max(-32768, int(s)))) for s in samples))

rate = 22050
base = os.path.dirname(os.path.abspath(__file__))

def jump():
    n = int(rate * 0.18)
    s = []
    for i in range(n):
        t = i / rate
        freq = 200 + 400 * (i / n)
        vol = 28000 * math.exp(-4 * i / n)
        s.append(vol * math.sin(2 * math.pi * freq * t))
    return s

def success():
    notes = [523, 659, 784]
    s = []
    for freq in notes:
        n = int(rate * 0.18)
        for i in range(n):
            t = i / rate
            vol = 26000 * math.exp(-3 * i / n)
            s.append(vol * math.sin(2 * math.pi * freq * t))
    return s

write_wav(f'{base}/bear_jump.wav', jump())
write_wav(f'{base}/bear_success.wav', success())
print('Created:', os.listdir(base))
