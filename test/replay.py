import argparse
import glob
import json
import os
import socket
import time

PROTOCOL = 1


def find_stint(path):
    if os.path.isdir(path):
        logs = sorted(glob.glob(os.path.join(path, 'log_*.json')))
        if not logs:
            raise SystemExit(f"[!] no log_*.json in {path}")
        path = logs[-1]
    base = os.path.splitext(path)[0]
    with open(base + '.json', encoding='utf-8') as f:
        log = json.load(f)
    if log.get('formatVersion') != 2:
        raise SystemExit("[!] only stint logs are supported (formatVersion 2)")
    return base + '.csv', log


def load_samples(csv_path, rates):
    samples = []
    with open(csv_path, encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\r\n')
            if not line:
                continue
            tag, t, values = line.split(';', 2)
            group = tag.strip('#')
            samples.append((float(t), group, int(rates[group]), values))
    return samples


def replay(samples, host, port, speed, loop):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    target = (host, port)
    duration = samples[-1][0]
    seq = 0
    offset = 0.0
    try:
        while True:
            start = time.perf_counter()
            next_status = 0
            for t, group, rate, values in samples:
                wait = start + t / speed - time.perf_counter()
                if wait > 0:
                    time.sleep(wait)
                seq += 1
                packet = f"APEX|{PROTOCOL}|{seq}|{group}|{rate}|{offset + t:.6f}|0|{values}"
                sock.sendto(packet.encode(), target)
                if t >= next_status:
                    print(f"[>] {t:6.1f} / {duration:.1f} s  {seq} packets")
                    next_status += 10
            if not loop:
                break
            # the clock keeps increasing across loops
            offset += duration
    except KeyboardInterrupt:
        pass
    finally:
        sock.close()
        print(f"[>] {seq} packets sent")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Apex TX stint replay")
    parser.add_argument('path', nargs='?', default=os.path.dirname(os.path.abspath(__file__)),
                        help="stint JSON or CSV, or a folder with stints (default: this script's folder)")
    parser.add_argument('--host', default='127.0.0.1', help="target address (default: 127.0.0.1)")
    parser.add_argument('--port', type=int, default=9996, help="target port (default: 9996)")
    parser.add_argument('--speed', type=float, default=1.0, help="playback speed (default: 1)")
    parser.add_argument('--loop', action='store_true', help="start over at the end of the stint")
    args = parser.parse_args()
    if args.speed <= 0:
        parser.error("--speed must be above 0")

    csv_path, log = find_stint(args.path)
    samples = load_samples(csv_path, log['rates'])
    if not samples:
        raise SystemExit(f"[!] {os.path.basename(csv_path)} has no samples")
    print(f"[>] {os.path.basename(csv_path)}: {len(samples)} samples, {samples[-1][0]:.1f} s")
    print(f"[>] sending to {args.host}:{args.port} at x{args.speed:g}")
    replay(samples, args.host, args.port, args.speed, args.loop)
