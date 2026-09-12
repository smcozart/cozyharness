/**
 * Pi adapter for the global dangerous-command guard.
 *
 * Wraps ~/.agents/hooks/deny-dangerous.sh (the davidondrej/skills guard):
 * every bash tool call is piped through the guard's exit-code contract
 * (exit 2 = block, reason on stderr). Fail-open: if the guard or jq is
 * missing, commands pass — the guard's own philosophy.
 *
 * User-level install so it guards every pi session (herdr workers included):
 *   cp .pi/extensions/deny-dangerous.ts ~/.pi/agent/extensions/
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";

const GUARD = join(homedir(), ".agents", "hooks", "deny-dangerous.sh");

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		if (event.toolName !== "bash") return;
		const command = (event.input as { command?: string }).command;
		if (!command) return;

		const result = spawnSync(GUARD, [], {
			input: JSON.stringify({ tool_input: { command } }),
			encoding: "utf8",
			timeout: 5000,
		});

		if (result.status === 2) {
			return {
				block: true,
				reason: result.stderr?.trim() || "Blocked by dangerous-command guard",
			};
		}
		// status 0 (allow), null (spawn failed/timeout), or missing guard: allow.
	});
}
