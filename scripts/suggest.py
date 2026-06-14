#!/usr/bin/env python3
"""suggest.py - Portfolio analysis and chain recommendations."""
import json, sys, os, subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
NETWORKS = json.load(open(os.path.join(ROOT_DIR, "assets", "networks.json")))
TOKENS = json.load(open(os.path.join(ROOT_DIR, "assets", "tokens.json")))
PRICES = json.load(open(os.path.join(ROOT_DIR, "assets", "priceFeeds.json")))

addr = sys.argv[1] if len(sys.argv) > 1 else None
if not addr:
    print("Usage: suggest <address>"); sys.exit(1)

def rpc_call(rpc, method, params):
    data = json.dumps({"jsonrpc":"2.0","method":method,"params":params,"id":1})
    try:
        r = subprocess.run(["curl","-s","-X","POST","--connect-timeout","8","--max-time","15",
            "-H","Content-Type: application/json","-d",data, rpc],
            capture_output=True, text=True, timeout=20)
        if r.returncode == 0 and r.stdout:
            return json.loads(r.stdout)
    except: pass
    return {}

def fetch_balance(rpc, address):
    r = rpc_call(rpc, "eth_getBalance", [address, "latest"])
    wei = r.get("result","0x0")
    if not wei or wei == "0x0": return 0
    try: return int(wei, 16) / 1e18
    except: return 0

def fetch_gas(rpc):
    r = rpc_call(rpc, "eth_gasPrice", [])
    wei = r.get("result","0x0")
    if not wei or wei == "0x0": return -1
    try: return round(int(wei, 16) / 1e9, 2)
    except: return -1

print("="*57)
print("|  Portfolio Suggestions                                    |")
print("|-" + "-"*53 + "|")
print(f"|  Address: {addr[:42]:42s}  |")
print("="*57)
print()

# Collect data
chains = []
for net in NETWORKS["networks"]:
    if net.get("type") == "solana": continue
    rpc = net.get("rpcUrl", "")
    if not rpc: continue
    try:
        bal = fetch_balance(rpc, addr)
        gas = fetch_gas(rpc)
    except:
        bal, gas = 0, 0
    chains.append({"name":net["name"], "chainId":net["chainId"], "token":net["nativeToken"],
                   "balance":bal, "gas":gas, "rpc":rpc, "type":net.get("type","")})

# Also check USDC balances
usdc_data = []
for net in NETWORKS["networks"]:
    chain_name = net["name"]
    tokens_list = TOKENS.get(chain_name, [])
    usdc_info = next((t for t in tokens_list if t["symbol"] == "USDC"), None)
    if not usdc_info: continue
    rpc = net.get("rpcUrl", "")
    if not rpc: continue
    usdc_addr = usdc_info["address"]
    decimals = usdc_info["decimals"]
    # We can't easily call balanceOf from Python without web3, skip for now
    # In production: use web3.py eth_call
    usdc_data.append({"chain":chain_name, "addr":usdc_addr, "decimals":decimals})

# Sort by gas (cheapest first)
chains.sort(key=lambda c: c["gas"])

# Suggestions
count = 0

# 1. Gas prices - ALL chains
cheapest = [c for c in chains if c["gas"] >= 0]
if cheapest: cheapest = cheapest[0]
print("  [GAS] Gas prices across chains:")
for c in chains:
    marker = " <<< CHEAPEST" if c == cheapest else ""
    gas_str = f"{c['gas']:.2f} gwei" if c["gas"] >= 0 else "N/A"
    print(f"    {c['name']:<22s} {gas_str:>12s}{marker}")
count += 1

# 2. Where you have native balance
has_balance = [c for c in chains if c["balance"] > 0]
if has_balance:
    print()
    print("  [BALANCE] Chains where you can pay gas:")
    for c in has_balance:
        print(f"    {c['name']:<20s} {c['balance']:>12.6f} {c['token']}")
    count += 1
else:
    print()
    print("  [BALANCE] No native balance on any chain. Fund a wallet first.")
    count += 1

# 3. Bridge recommendation
rich = sorted(has_balance, key=lambda c: c["balance"], reverse=True)
if rich and cheapest and cheapest["name"] != rich[0]["name"]:
    src = rich[0]
    src_gas = f"{src['gas']:.2f} gwei" if src["gas"] >= 0 else "N/A"
    dst_gas = f"{cheapest['gas']:.2f} gwei" if cheapest["gas"] >= 0 else "N/A"
    print()
    print(f"  [BRIDGE] You have {src['balance']:.4f} {src['token']} on {src['name']}")
    print(f"           Gas on {src['name']}: {src_gas}")
    print(f"           Gas on {cheapest['name']}: {dst_gas}")
    if cheapest["gas"] >= 0 and src["gas"] >= 0 and cheapest["gas"] < src["gas"]:
        print(f"  -> Consider bridging to {cheapest['name']} for cheaper tx")
    count += 1

# 4. Where USDC is available
if usdc_data:
    print()
    print(f"  [USDC] Available on {len(usdc_data)} chains:")
    for u in usdc_data[:5]:
        print(f"    {u['chain']}")
    count += 1

print()
print(f"  {count} suggestions generated.")
