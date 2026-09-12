/**
 * Context Footer - always-on footer showing live context window fill.
 *
 * Shows the LAST assistant message's totalTokens as a % of the model's
 * context window — i.e. how full the window actually is right now, not
 * cumulative session spend. Color shifts green -> yellow -> red as the
 * window fills. Also shows session cost and git branch.
 *
 * Drop in .pi/extensions/ — no commands, no toggles, it just runs.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

export default function (pi: ExtensionAPI) {
	let tuiRef: { requestRender: () => void } | null = null;

	// Re-render the footer after every turn so the meter stays live.
	pi.on("turn_end", async () => {
		tuiRef?.requestRender();
	});

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			tuiRef = tui;
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					// Live window fill: the last assistant message's usage is what
					// the model carried into its most recent turn.
					let lastTotal = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							if (m.usage) {
								lastTotal = m.usage.totalTokens || lastTotal;
							}
						}
					}

					const usage = ctx.getContextUsage();
					const window_ = ctx.model?.contextWindow ?? 200000;
					const used = usage?.tokens ?? lastTotal;
					const pct = Math.min(100, (used / window_) * 100);

					const fmt = (n: number) =>
						n < 1000 ? `${n}` : n < 1_000_000 ? `${Math.round(n / 1000)}k` : `${(n / 1_000_000).toFixed(1)}M`;
					const color = pct < 50 ? "success" : pct < 75 ? "warning" : "error";
					const filled = Math.round(pct / 10);
					const bar = "█".repeat(filled) + "░".repeat(10 - filled);
					const context = theme.fg(
						color as "success",
						`ctx ${bar} ${pct.toFixed(0)}% (${fmt(used)}/${fmt(window_)})`,
					);

					const cwd = ctx.cwd.split(/[\\/]/).pop() || ctx.cwd;
					const branch = footerData.getGitBranch() || "no-branch";
					const rawModel = ctx.model?.id || "no-model";
					const model = rawModel.endsWith("/auto") ? "auto" : rawModel.split("/").pop() || rawModel;
					const line =
						theme.fg("dim", `${cwd} | ${model} | `) +
						theme.fg("accent", `${branch} | `) +
						context;
					return [truncateToWidth(line, width)];
				},
			};
		});
	});
}
