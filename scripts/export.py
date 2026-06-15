#!/usr/bin/env python3
"""export.py — Generate CSV or HTML portfolio report."""
import json, os, sys, time, subprocess

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

addr = sys.argv[1] if len(sys.argv) > 1 else None
fmt = sys.argv[2] if len(sys.argv) > 2 else "csv"
if not addr:
    print("Usage: export.py <address> [csv|html]")
    sys.exit(1)

nets = json.load(open(os.path.join(ROOT, "assets", "networks.json")))
tokens = json.load(open(os.path.join(ROOT, "assets", "tokens.json")))
prices = json.load(open(os.path.join(ROOT, "assets", "priceFeeds.json")))

rows = []
for n in nets["networks"]:
    rpc = n.get("rpcUrl","")
    name = n["name"]
    if not rpc or n.get("type","") in ["solana","near"]: continue
    bal = balance(addr, rpc)
    if bal > 0:
        rows.append({"chain": name, "token": n["nativeToken"], "balance": bal, "chainId": n.get("chainId",0)})

ts = time.strftime("%Y-%m-%d %H:%M:%S")

if fmt == "csv":
    path = os.path.join(ROOT, "data", f"portfolio_{addr[:10]}.csv")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(f"# Portfolio Report - {addr}\n")
        f.write(f"# Generated: {ts}\n")
        f.write("Chain,ChainID,Token,Balance\n")
        for r in sorted(rows, key=lambda r: r["balance"], reverse=True):
            f.write(f"{r['chain']},{r['chainId']},{r['token']},{r['balance']:.8f}\n")
    print(f"CSV exported: {path} ({len(rows)} chains)")

elif fmt == "html":
    path = os.path.join(ROOT, "data", f"portfolio_{addr[:10]}.html")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    total = sum(r["balance"] for r in rows)
    rows_html = "\n".join(
        f"<tr><td>{r['chain']}</td><td>{r['chainId']}</td><td>{r['token']}</td><td>{r['balance']:.6f}</td></tr>"
        for r in sorted(rows, key=lambda r: r["balance"], reverse=True)
    )
    html = f"""<!DOCTYPE html><html><head><title>Pharos Portfolio - {addr[:10]}</title>
<style>body{{font-family:monospace;background:#0d1117;color:#e6edf3;padding:2em}}
table{{border-collapse:collapse;width:100%}} th,td{{padding:8px 16px;text-align:left;border-bottom:1px solid #30363d}}
th{{background:#161b22}} tr:hover{{background:#1c2129}}
h1{{color:#7b3fe4}} .total{{font-size:1.2em;margin:1em 0}}</style></head>
<body><h1>Pharos Cross-Chain Portfolio</h1>
<p>Address: {addr}<br>Generated: {ts}<br>Active chains: {len(rows)}</p>
<p class=total>Total chains with balance: {len(rows)}</p>
<table><tr><th>Chain</th><th>ChainID</th><th>Token</th><th>Balance</th></tr>
{rows_html}</table></body></html>"""
    with open(path, "w") as f: f.write(html)
    print(f"HTML exported: {path} ({len(rows)} chains)")
