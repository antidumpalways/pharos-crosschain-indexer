#!/usr/bin/env python3
"""multi.py — Query multiple addresses across ALL chains with native + ERC-20 tokens."""
import json, os, sys, subprocess
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
nets = json.load(open(os.path.join(ROOT, "assets", "networks.json")))
tokens_db = json.load(open(os.path.join(ROOT, "assets", "tokens.json")))
prices_db = json.load(open(os.path.join(ROOT, "assets", "priceFeeds.json")))

def rpc_call(rpc_url, data):
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","8","--max-time","12",
            "-X","POST","-H","Content-Type: application/json","-d",json.dumps(data), rpc_url],
            capture_output=True, text=True, timeout=15)
        return json.loads(r.stdout)
    except: return {}

def native_balance(addr, rpc_url):
    r = rpc_call(rpc_url, {"jsonrpc":"2.0","method":"eth_getBalance","params":[addr,"latest"],"id":1})
    try: return int(r.get("result","0x0"),16) / 1e18
    except: return 0

def erc20_balance(addr, token_addr, rpc_url):
    call_data = "0x70a08231" + addr[2:].lower().rjust(64,"0")
    r = rpc_call(rpc_url, {"jsonrpc":"2.0","method":"eth_call","params":[{"to":token_addr,"data":call_data},"latest"],"id":1})
    try: return int(r.get("result","0x0"),16)
    except: return 0

addrs = sys.argv[1:]
if not addrs:
    print("Usage: multi.py <addr1> <addr2> ...")
    print("Example: multi.py 0xf39Fd6... 0xd8dA6BF2...")
    print("  Scans ALL 112 chains + ERC-20 tokens. Shows only non-zero balances.")
    sys.exit(1)

# Pre-load ERC-20 tokens per chain
chain_tokens = {}
for chain_name, tks in tokens_db.items():
    chain_tokens[chain_name] = tks

print(f"\n  Multi-Address Portfolio ({len(addrs)} address{'es' if len(addrs)>1 else ''} x 112 chains)")
print(f"  {'Address':<44s} {'Chain':<22s} {'Token':>8s} {'Balance':>14s}")
print(f"  {'-'*44} {'-'*22} {'-'*8} {'-'*14}")

total_chains = 0
found = defaultdict(int)

for addr in addrs[:10]:  # max 10 addresses
    for n in nets["networks"]:
        name = n["name"]
        rpc = n.get("rpcUrl","")
        ntype = n.get("type","")
        if not rpc or ntype in ["solana","near"]: continue

        # Native balance
        bal = native_balance(addr, rpc)
        if bal > 0:
            print(f"  {addr:<44s} {name:<22s} {n['nativeToken']:>8s} {bal:>14.6f}")
            found[addr] += 1

        # ERC-20 tokens on this chain
        tokens = chain_tokens.get(name, [])
        for tk in tokens[:5]:  # limit to 5 tokens per chain for speed
            raw = erc20_balance(addr, tk["address"], rpc)
            if raw > 0:
                human = round(raw / (10 ** tk["decimals"]), 6)
                if human > 0.000001:
                    print(f"  {addr:<44s} {name:<22s} {tk['symbol']:>8s} {human:>14.6f}")
                    found[addr] += 1

    total_chains += 1

if found:
    print(f"\n  Summary:")
    for addr, count in found.items():
        print(f"    {addr}: {count} balances found across all chains")
else:
    print(f"\n  No balances found on any chain.")
