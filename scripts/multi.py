#!/usr/bin/env python3
"""multi.py — Query multiple addresses at once."""
import json, os, sys, subprocess

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def get_balance(addr, rpc):
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","8","--max-time","12",
            "-X","POST","-H","Content-Type: application/json",
            "-d",json.dumps({"jsonrpc":"2.0","method":"eth_getBalance","params":[addr,"latest"],"id":1}), rpc],
            capture_output=True, text=True, timeout=15)
        wei = int(json.loads(r.stdout).get("result","0x0"), 16)
        return round(wei / 1e18, 6)
    except: return 0

addrs = sys.argv[1:]
if not addrs:
    print("Usage: multi.py <addr1> <addr2> ...")
    print("Example: multi.py 0xf39F... 0xd8dA... 0xFF11...")
    sys.exit(1)

nets = json.load(open(os.path.join(ROOT_DIR, "assets", "networks.json")))

print(f"\n  Multi-Address Balance ({len(addrs)} addresses × chains)")
print(f"  {'Address':<44s} {'Chain':<22s} {'Balance':>14s}")
print(f"  {'-'*44} {'-'*22} {'-'*14}")

for addr in addrs[:20]:  # max 20
    short = addr[:10] + "..." + addr[-6:]
    for n in nets["networks"][:15]:  # first 15 chains for speed
        rpc = n.get("rpcUrl","")
        if not rpc or n.get("type","") in ["solana","near"]: continue
        bal = get_balance(addr, rpc)
        if bal > 0:
            print(f"  {addr:<44s} {n['name']:<22s} {bal:>14.6f} {n['nativeToken']}")
