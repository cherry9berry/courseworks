"""
P2P Мессенджер — Курсовой проект по СПО
Архитектура: Peer-to-Peer (каждый узел = сервер + клиент одновременно)
Протокол: Length-Prefix Framing + JSON поверх TCP
"""

import socket
import threading
import json
import struct
import time
import sys


# ПРОТОКОЛ
# Каждый пакет: [4 байта длины (uint32, big-endian)][JSON-тело (UTF-8)]
# Типы сообщений: HELLO — рукопожатие, MSG — сообщение, BYE — отключение

def pack(msg: dict) -> bytes:
    body = json.dumps(msg, ensure_ascii=False).encode("utf-8")
    return struct.pack(">I", len(body)) + body


def recv_exact(sock: socket.socket, n: int) -> bytes | None:
    # TCP потоковый — recv() может вернуть меньше n байт, читаем в цикле
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            return None
        buf += chunk
    return buf


def unpack(sock: socket.socket) -> dict | None:
    header = recv_exact(sock, 4)
    if header is None:
        return None
    length = struct.unpack(">I", header)[0]
    body = recv_exact(sock, length)
    if body is None:
        return None
    return json.loads(body.decode("utf-8"))


class Node:
    def __init__(self, port: int, username: str):
        self.port = port
        self.username = username
        self.peers: dict[str, socket.socket] = {}  # "ip:port" -> сокет
        self.lock = threading.Lock()  # защита peers от гонки потоков
        self.running = True

    def start(self):
        t = threading.Thread(target=self._server_loop, daemon=True)
        t.start()
        print(f"  Твой адрес: 127.0.0.1:{self.port}")
        print("  /connect <ip> <port>  — подключиться к пиру")
        print("  /peers                — список подключённых")
        print("  /quit                 — выход\n")
        self._cli_loop()

    # Сервер: ждёт входящих подключений

    def _server_loop(self):
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind(("0.0.0.0", self.port))
        srv.listen(10)
        srv.settimeout(1.0)  # Таймаут, чтобы accept() не блокировал поток вечно (чистый выход)
        while self.running:
            try:
                conn, addr = srv.accept()
                threading.Thread(target=self._handle_incoming, args=(conn, addr), daemon=True).start()
            except socket.timeout:
                continue
            except Exception:
                break
        srv.close()

    def _handle_incoming(self, conn: socket.socket, addr: tuple):
        # Ждём HELLO от пира, отвечаем своим HELLO
        msg = unpack(conn)
        if not msg or msg.get("type") != "HELLO":
            conn.close()
            return

        peer_name = msg["username"]
        peer_key = f"{addr[0]}:{msg['port']}"

        with self.lock:
            self.peers[peer_key] = conn

        conn.sendall(pack({"type": "HELLO", "username": self.username, "port": self.port}))
        print(f"\n[+] {peer_name} подключился\n> ", end="", flush=True)
        self._read_loop(conn, peer_key, peer_name)

    # Клиент: исходящее подключение

    def connect(self, ip: str, port: int):
        key = f"{ip}:{port}"
        with self.lock:
            if key in self.peers:
                print(f"[!] Уже подключён к {key}")
                return
        try:
            conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            conn.settimeout(5)
            conn.connect((ip, port))
            conn.settimeout(None)

            conn.sendall(pack({"type": "HELLO", "username": self.username, "port": self.port}))

            resp = unpack(conn)
            if not resp or resp.get("type") != "HELLO":
                conn.close()
                print("[!] Нет ответа на рукопожатие")
                return

            peer_name = resp["username"]
            with self.lock:
                self.peers[key] = conn

            print(f"[+] Подключился к {peer_name} ({key})")
            threading.Thread(target=self._read_loop, args=(conn, key, peer_name), daemon=True).start()

        except Exception as e:
            print(f"[!] Ошибка подключения: {e}")

    # Общий цикл чтения сообщений от пира

    def _read_loop(self, conn: socket.socket, key: str, peer_name: str):
        try:
            while self.running:
                msg = unpack(conn)
                if msg is None:
                    print(f"\n[-] {peer_name} отключился\n> ", end="", flush=True)
                    break
                if msg["type"] == "MSG":
                    ts = time.strftime("%H:%M", time.localtime(msg.get("timestamp", time.time())))
                    print(f"\n[{ts}] {msg['username']}: {msg['text']}\n> ", end="", flush=True)
                elif msg["type"] == "BYE":
                    print(f"\n[-] {peer_name} вышел\n> ", end="", flush=True)
                    break
        except (ConnectionResetError, BrokenPipeError, OSError):
            pass
        finally:
            with self.lock:
                self.peers.pop(key, None)
            conn.close()

    def broadcast(self, text: str):
        pkt = pack({"type": "MSG", "username": self.username,
                    "text": text, "timestamp": time.time()})
        dead = []
        with self.lock:
            snapshot = dict(self.peers)
        for key, conn in snapshot.items():
            try:
                conn.sendall(pkt)
            except Exception:
                dead.append(key)
        with self.lock:
            for key in dead:
                self.peers.pop(key, None)

    def _cli_loop(self):
        while self.running:
            try:
                line = input("> ").strip()
            except (EOFError, KeyboardInterrupt):
                break

            if not line:
                continue
            elif line == "/quit":
                self._shutdown()
                break
            elif line == "/peers":
                with self.lock:
                    keys = list(self.peers.keys())
                print("Подключённые:", ", ".join(keys) if keys else "никого нет")
            elif line.startswith("/connect "):
                parts = line.split()
                if len(parts) == 3:
                    try:
                        self.connect(parts[1], int(parts[2]))
                    except ValueError:
                        print("[!] Порт должен быть числом")
                else:
                    print("[!] Использование: /connect <ip> <port>")
            elif line.startswith("/"):
                print("[!] Неизвестная команда")
            else:
                with self.lock:
                    count = len(self.peers)
                if count == 0:
                    print("[!] Нет подключённых пиров")
                else:
                    print(f"[{time.strftime('%H:%M')}] Ты: {line}")
                    self.broadcast(line)

    def _shutdown(self):
        self.running = False
        bye = pack({"type": "BYE", "username": self.username})
        with self.lock:
            for conn in self.peers.values():
                try:
                    conn.sendall(bye)
                    conn.close()
                except Exception:
                    pass
        print("Пока!")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Использование: python {sys.argv[0]} <port> [username]")
        sys.exit(1)

    port = int(sys.argv[1])
    username = sys.argv[2] if len(sys.argv) > 2 else f"User_{port}"

    print(f"\nTrashPanda P2P Messenger | СПО | порт {port}\n")
    Node(port, username).start()
