#!/usr/bin/env python3
"""diff.py — Save a balance snapshot and compare later."""
import json, os, sys, time, subprocess

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNAP_FILE = os.path.join(ROOT_DIR, "data", "snapshot.json")

def get_balance(addr, rpc):
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","8","--max-time","12",
            "-X","POST","-H","Content-Type: application/json",
            "-d",json.dumps({"jsonrpc":"2.0","method":"eth_getBalance","params":[addr,"latest"],"id":1}), rpc],
            capture_output=True, text=True, timeout=15)
        wei = int(json.loads(r.stdout).get("result","0x0"), 16)
        return round(wei / 1e18, 6)
    except: return 0

def erc20(addr, token_addr, rpc):
    call_data = "0x70a08231" + addr[2:].lower().rjust(64,"0")
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","8","--max-time","12",
            "-X","POST","-H","Content-Type: application/json",
            "-d",json.dumps({"jsonrpc":"2.0","method":"eth_call","params":[{"to":token_addr,"data":call_data},"latest"],"id":1}), rpc],
            capture_output=True, text=True, timeout=15)
        return int(json.loads(r.stdout).get("result","0x0"), 16)
    except: return 0

TOKENS_DB = json.load(open(os.path.join(ROOT_DIR, "assets", "tokens.json")))

def cmd_save(addr):
    nets = json.load(open(os.path.join(ROOT_DIR, "assets", "networks.json")))
    snap = {"address": addr, "timestamp": int(time.time()), "balances": {}}
    for n in nets["networks"]:
        rpc = n.get("rpcUrl","")
        if not rpc or n.get("type","") in ["solana","near","bitcoin"]: continue
        bal = get_balance(addr, rpc)
        if bal > 0:
            snap["balances"][n["name"]] = {"balance": bal, "token": n["nativeToken"]}
    os.makedirs(os.path.dirname(SNAP_FILE), exist_ok=True)
    json.dump(snap, open(SNAP_FILE, "w"), indent=2)
    print(f"Snapshot saved: {len(snap['balances'])} chains with balance for {addr}")
    print(f"File: {SNAP_FILE}")

def cmd_diff(addr):
    if not os.path.exists(SNAP_FILE):
        print("No snapshot found. Run 'diff save <addr>' first.")
        return
    snap = json.load(open(SNAP_FILE))
    nets = json.load(open(os.path.join(ROOT_DIR, "assets", "networks.json")))
    changes = []
    for n in nets["networks"]:
        name = n["name"]
        rpc = n.get("rpcUrl","")
        if not rpc or n.get("type","") in ["solana","near","bitcoin"]: continue
        bal = get_balance(addr, rpc)
        prev = snap["balances"].get(name, {}).get("balance", 0)
        if abs(bal - prev) > 0.000001:
            delta = bal - prev
            changes.append((name, prev, bal, delta, n["nativeToken"]))
    
    changes.sort(key=lambda c: abs(c[3]), reverse=True)
    print(f"\n  Balance Changes for {addr}")
    print(f"  Snapshot: {time.ctime(snap['timestamp'])}")
    print(f"  {'Chain':<22s} {'Before':>14s} {'After':>14s} {'Delta':>14s}")
    for name, prev, bal, delta, tok in changes[:20]:
        sign = "+" if delta > 0 else ""
        print(f"  {name:<22s} {prev:>14.6f} {bal:>14.6f} {sign}{delta:>13.6f} {tok}")
    if not changes:
        print("  No changes detected.")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "diff"
    addr = sys.argv[2] if len(sys.argv) > 2 else None
    if not addr: print("Usage: diff.py save|diff <address>"); sys.exit(1)
    if cmd == "save": cmd_save(addr)
    elif cmd == "diff": cmd_diff(addr)
    else: print(f"Unknown: {cmd}")
