#!/usr/bin/env node
/**
 * pharos-crosschain-indexer — Node.js CLI wrapper for the bash indexer.
 *
 * Usage:
 *   npx pharos-crosschain-indexer balance <address>
 *   npx pharos-crosschain-indexer portfolio <address>
 *   npx pharos-crosschain-indexer tx <hash>
 *   npx pharos-crosschain-indexer label <address>
 *   npx pharos-crosschain-indexer verify <address>
 */
import { execSync } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const INDEXER = join(__dirname, "..", "scripts", "indexer");

const cmd = process.argv[2];
const args = process.argv.slice(3);

if (!cmd || cmd === "help" || cmd === "--help" || cmd === "-h") {
    execSync(`bash "${INDEXER}" help`, { stdio: "inherit" });
    process.exit(0);
}

const valid = ["balance", "tx", "portfolio", "label", "verify"];
if (!valid.includes(cmd)) {
    console.error(`Unknown command: ${cmd}`);
    console.error(`Valid commands: ${valid.join(", ")}`);
    process.exit(1);
}

try {
    execSync(`bash "${INDEXER}" ${cmd} ${args.join(" ")}`, { stdio: "inherit" });
} catch (e) {
    process.exit(1);
}
