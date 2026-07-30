"""
Test data receiver
Run:
python receiver.py
or
python receiver.py --host <IP_ADDR> --port <PORT> 
"""

import socket
import argparse

def start_receiver(host='127.0.0.1', port=9996):
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    server_address = (host, port)
    print(f"[>] starting UDP receiver on {host}:{port}")
    sock.bind(server_address)
    
    print("[>] listening for data...") # CTRL+C to stop
    
    try:
        while True:
            # buffer size: 4096 bytes
            data, address = sock.recvfrom(4096)
            payload = data.decode('utf-8', errors='replace')

            print(f"[{address[0]}:{address[1]}] {len(data)} bytes -> {payload}")
            
    except KeyboardInterrupt:
        print("\n[>] stopping receiver...")
    finally:
        sock.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Apex UDP Telemetry Receiver")
    parser.add_argument('--host', type=str, default='127.0.0.1', help="host IP to bind to (default: 127.0.0.1)")
    parser.add_argument('--port', type=int, default=9996, help="port to bind to (default: 9996)")
    args = parser.parse_args()
    
    start_receiver(args.host, args.port)
