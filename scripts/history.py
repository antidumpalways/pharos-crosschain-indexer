#!/usr/bin/env python3
"""history.py — Track balance over time, show time-series."""
import json, os, sys, time, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HIST_FILE = os.path.join(ROOT, "data", "history.jsonl")

def rpc(rpc_url, method, params):
    d = json.dumps({"jsonrpc":"2.0","method":method,"params":params,"id":1})
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","6","--max-time","10",
            "-X","POST","-H","Content-Type: application/json","-d",d, rpc_url],
            capture_output=True, text=True, timeout=12)
        return json.loads(r.stdout)
    except: return {}

def balance(addr, rpc_url):
    r = rpc(rpc_url, "eth_getBalance", [addr, "latest"])
    try: return int(r.get("result","0x0"), 16) / 1e18
    except: return 0

nets = json.load(open(os.path.join(ROOT, "assets", "networks.json")))
cmd = sys.argv[1] if len(sys.argv) > 1 else "show"
addr = sys.argv[2] if len(sys.argv) > 2 else None

if cmd == "record":
    if not addr: print("Usage: history.py record <address>"); sys.exit(1)
    entry = {"timestamp": int(time.time()), "address": addr, "balances": {}}
    for n in nets["networks"]:
        rpc_url = n.get("rpcUrl","")
        if not rpc_url or n.get("type","") in ["solana","near"]: continue
        bal = balance(addr, rpc_url)
        if bal > 0:
            entry["balances"][n["name"]] = bal
    os.makedirs(os.path.dirname(HIST_FILE), exist_ok=True)
    with open(HIST_FILE, "a") as f: f.write(json.dumps(entry) + "\n")
    print(f"Recorded: {len(entry['balances'])} chains with balance at {time.ctime(entry['timestamp'])}")

elif cmd == "show":
    if not os.path.exists(HIST_FILE):
        print("No history yet. Run 'history.py record <addr>' first.")
        sys.exit(0)
    entries = [json.loads(l) for l in open(HIST_FILE) if l.strip()]
    if addr: entries = [e for e in entries if e["address"] == addr]
    print(f"\n  Balance History ({len(entries)} snapshots)")
    print(f"  {'Time':<20s} {'Chains':>8s} {'Top Chain':<22s} {'Balance':>14s}")
    chains_list = {}
    for e in entries:
        top = max(e["balances"].items(), key=lambda x: x[1]) if e["balances"] else ("none", 0)
        print(f"  {time.ctime(e['timestamp']):<20s} {len(e['balances']):>8d} {top[0]:<22s} {top[1]:>14.6f}")
        for chain, bal in e["balances"].items():
            if chain not in chains_list: chains_list[chain] = []
            chains_list[chain].append((e["timestamp"], bal))
    print(f"\n  Chain-specific trends:")
    for chain in sorted(chains_list.keys())[:10]:
        pts = sorted(chains_list[chain])[:5]
        first, last = pts[0][1], pts[-1][1]
        delta = last - first
        sign = "+" if delta > 0 else ""
        print(f"  {chain:<20s} {first:>14.6f} -> {last:>14.6f} ({sign}{delta:.6f})")

elif cmd == "count":
    if not os.path.exists(HIST_FILE):
        print("0"); sys.exit(0)
    entries = [l for l in open(HIST_FILE) if l.strip()]
    print(len(entries))

else:
    print("Usage: history.py record|show|count [address]")
    print("  record <addr>  Save current balances")
    print("  show [addr]    Display history")
    print("  count          Number of snapshots")
