"""Exercise search domains and DNS-over-TCP using an isolated resolver."""
import pathlib
import socket
import struct
import subprocess
import sys
import threading

queries = []

def answer(query, tcp=False):
    """Return one deterministic IPv4 answer, truncating TCP-test UDP replies."""
    offset, labels = 12, []
    while query[offset]:
        size = query[offset]
        labels.append(query[offset + 1:offset + size + 1].decode())
        offset += size + 1
    offset += 5
    name = ".".join(labels)
    queries.append((name, tcp))
    truncated = name == "tcp.audit.test" and not tcp
    flags = 0x8380 if truncated else 0x8180
    count = 0 if truncated else 1
    header = query[:2] + struct.pack("!HHHHH", flags, 1, count, 0, 0)
    record = b"\xc0\x0c" + struct.pack("!HHIH", 1, 1, 60, 4)
    return header + query[12:offset] + (b"" if truncated else record + b"\x7f\x00\x00\x2a")


def serve_udp(server):
    """Serve DNS queries over UDP."""
    while True:
        query, peer = server.recvfrom(4096)
        server.sendto(answer(query), peer)


def receive(connection, size):
    """Read an exact DNS frame length."""
    result = b""
    while len(result) < size:
        chunk = connection.recv(size - len(result))
        if not chunk:
            raise RuntimeError("Incomplete DNS frame")
        result += chunk
    return result


def serve_tcp(server):
    """Serve DNS queries over TCP."""
    while True:
        connection, _ = server.accept()
        with connection:
            size = struct.unpack("!H", receive(connection, 2))[0]
            response = answer(receive(connection, size), tcp=True)
            connection.sendall(struct.pack("!H", len(response)) + response)


udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
for server in (udp, tcp):
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", 53))
tcp.listen()
threading.Thread(target=serve_udp, args=(udp,), daemon=True).start()
threading.Thread(target=serve_tcp, args=(tcp,), daemon=True).start()
configuration = pathlib.Path("/etc/resolv.conf")
original = configuration.read_bytes()
try:
    configuration.write_text("nameserver 127.0.0.1\nsearch audit.test\noptions timeout:1 attempts:1\n")
    subprocess.run(sys.argv[1:], check=True, timeout=30)
    assert ("node.audit.test", False) in queries, queries
    assert ("tcp.audit.test", True) in queries, queries
finally:
    configuration.write_bytes(original)
