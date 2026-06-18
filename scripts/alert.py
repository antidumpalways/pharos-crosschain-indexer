#!/usr/bin/env python3
"""alert.py — Watch address balances, alert on changes above threshold."""
import json, os, sys, time, subprocess, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def rpc_call(rpc, method, params):
    d = json.dumps({"jsonrpc":"2.0","method":method,"params":params,"id":1})
    try:
        r = subprocess.run(["curl","-s","--connect-timeout","6","--max-time","10",
            "-X","POST","-H","Content-Type: application/json","-d",d, rpc],
            capture_output=True, text=True, timeout=12)
        return json.loads(r.stdout)
    except: return {}

def balance(addr, rpc):
    r = rpc_call(rpc, "eth_getBalance", [addr, "latest"])
    try: return int(r.get("result","0x0"), 16) / 1e18
    except: return 0

nets = json.load(open(os.path.join(ROOT, "assets", "networks.json")))
addr = sys.argv[1] if len(sys.argv) > 1 else None
chain = sys.argv[2] if len(sys.argv) > 2 else "all"
threshold = float(sys.argv[3]) if len(sys.argv) > 3 else 0.01
interval = int(sys.argv[4]) if len(sys.argv) > 4 else 30
# Optional 5th arg: "all" to scan all 112 chains, or default to top 15 for speed
scope = sys.argv[5] if len(sys.argv) > 5 else "top15"

if not addr:
    print("Usage: alert.py <address> [chain] [threshold-eth] [interval-sec] [all|top15]")
    print("Example: alert.py <address> atlantic-testnet 1.0 60 top15")
    print("         alert.py <address> all 0.01 30 all")
    sys.exit(1)

# Get initial baseline
baseline = {}
active = []
network_list = nets["networks"]
if scope != "all":
    network_list = network_list[:15]
for n in network_list:
    name = n["name"]
    rpc = n.get("rpcUrl","")
    if not rpc: continue
    if chain != "all" and name != chain: continue
    if n.get("type","") in ["solana","near"]: continue
    b = balance(addr, rpc)
    baseline[name] = {"rpc": rpc, "balance": b, "token": n["nativeToken"]}
    active.append(name)

print(f"\n  [*] Monitoring {addr[:10]}... ({len(active)} chains, every {interval}s, threshold +/-{threshold})")
print(f"  Press Ctrl+C to stop.\n")

try:
    while True:
        time.sleep(interval)
        for name in active:
            rpc = baseline[name]["rpc"]
            prev = baseline[name]["balance"]
            curr = balance(addr, rpc)
            delta = curr - prev
            if abs(delta) >= threshold:
                sign = "[UP]  +" if delta > 0 else "[DN]  "
                ts = time.strftime("%H:%M:%S")
                print(f"  [{ts}] {name:<22s} {sign}{delta:>12.6f} {baseline[name]['token']}  (was {prev:.6f}, now {curr:.6f})")
                baseline[name]["balance"] = curr
            else:
                baseline[name]["balance"] = curr
except KeyboardInterrupt:
    print("\n  Stopped.")
