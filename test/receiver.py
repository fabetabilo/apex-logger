import argparse
import socket
import time
from collections import Counter

PROTOCOL = 1


# APEX|<protocol>|<seq>|<group>|<rate>|<clock>|<sessionTimeLeft>|<values>
def parse(payload):
    fields = payload.split('|', 7)
    if len(fields) != 8 or fields[0] != 'APEX' or fields[1] != str(PROTOCOL) or not fields[2].isdigit():
        return None
    return int(fields[2]), fields[3]


def start_receiver(host, port, stats):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, port))
    sock.settimeout(1)
    print(f"[>] listening on {host}:{port}")

    last_seq = None
    received = lost = 0
    counts = Counter()
    next_stats = time.monotonic() + 1
    try:
        while True:
            now = time.monotonic()
            if stats and now >= next_stats:
                line = "  ".join(f"{g}={n}" for g, n in sorted(counts.items())) or "none"
                print(f"[>] packets/s: {line}")
                counts.clear()
                next_stats = now + 1

            try:
                data, address = sock.recvfrom(4096)
            except socket.timeout:
                continue
            received += 1
            payload = data.decode('utf-8', errors='replace')
            if not stats:
                print(f"[{address[0]}:{address[1]}] {len(data)} bytes -> {payload}")

            packet = parse(payload)
            if not packet:
                print(f"[!] unknown packet: {payload[:80]}")
                continue
            seq, group = packet
            counts[group] += 1
            if last_seq is not None:
                if seq > last_seq + 1:
                    lost += seq - last_seq - 1
                    print(f"[!] {seq - last_seq - 1} packets lost before seq {seq}")
                elif seq <= last_seq:
                    print(f"[>] sequence restarted at {seq}")
            last_seq = seq
    except KeyboardInterrupt:
        pass
    finally:
        sock.close()
        print(f"\n[>] {received} packets received, {lost} lost")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Apex TX receiver")
    parser.add_argument('--host', default='127.0.0.1', help="address to listen on (default: 127.0.0.1)")
    parser.add_argument('--port', type=int, default=9996, help="port to listen on (default: 9996)")
    parser.add_argument('--stats', action='store_true', help="print packets per second per group instead of every packet")
    args = parser.parse_args()

    start_receiver(args.host, args.port, args.stats)
