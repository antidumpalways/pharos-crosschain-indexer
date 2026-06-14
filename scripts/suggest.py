#!/usr/bin/env python3
"""suggest.py - Portfolio analysis and chain recommendations."""
import json, sys, os, subprocess, tempfile, urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
NETWORKS = json.load(open(os.path.join(ROOT_DIR, "assets", "networks.json")))
TOKENS = json.load(open(os.path.join(ROOT_DIR, "assets", "tokens.json")))
PRICES = json.load(open(os.path.join(ROOT_DIR, "assets", "priceFeeds.json")))

addr = sys.argv[1] if len(sys.argv) > 1 else None
if not addr:
    print("Usage: suggest <address>"); sys.exit(1)

def rpc_call(rpc, method, params):
    data = json.dumps({"jsonrpc":"2.0","method":method,"params":params,"id":1}).encode()
    try:
        req = urllib.request.Request(rpc, data, {"Content-Type":"application/json"})
        return json.loads(urllib.request.urlopen(req, timeout=10).read())
    except: return {}

def fetch_balance(rpc, address, token_type="native"):
    if token_type == "native":
        r = rpc_call(rpc, "eth_getBalance", [address, "latest"])
        wei = int(r.get("result","0x0"), 16)
        return wei / 1e18
    return 0

def fetch_gas(rpc):
    r = rpc_call(rpc, "eth_gasPrice", [])
    wei = int(r.get("result","0x0"), 16)
    return round(wei / 1e9, 2)

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

# 1. Cheapest gas
cheapest = chains[0]
print(f"  [GAS] Cheapest chain: {cheapest['name']} at {cheapest['gas']} gwei")
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
if rich and cheapest["name"] != rich[0]["name"]:
    print()
    print(f"  [BRIDGE] You have {rich[0]['balance']:.4f} {rich[0]['token']} on {rich[0]['name']}")
    print(f"           Gas on {rich[0]['name']}: {rich[0]['gas']} gwei")
    print(f"           Gas on {cheapest['name']}: {cheapest['gas']} gwei")
    if cheapest["gas"] < rich[0]["gas"]:
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
