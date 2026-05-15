# persona-coverage

Analyze a brand's full Meta ad portfolio for persona coverage gaps and surface validated gap opportunities from Reddit and X.

## What it does

1. **Pulls every active ad** from a brand's Meta Ad Library pages (owned + partner/affiliate)
2. **Gemini-verifies every ad** — watches each video frame-by-frame to classify who's on camera, the format, setting, and creative vehicle (never trusts metadata/format tags alone)
3. **Builds a Macro × Vehicle coverage matrix** showing what the brand covers and where the white space is
4. **Mines Reddit and X** for unaddressed personas with verified verbatim quotes
5. **Validates demand** for every persona (existing + gap) against real X conversation signals
6. **Produces a prioritized gap brief** with confidence levels on every claim

## Prerequisites

| Requirement | Why | How to get it |
|---|---|---|
| **Claude Code connected to Claude.ai** | Provides the Ad Library MCP tools (`resolve-company`, `meta-search-ads`, `meta-get-ad`, `analyze-creatives`) for pulling ads and running Gemini video analysis. These are built-in Claude.ai tools — no separate install needed. | [claude.ai/code](https://claude.ai/code) |
| **curl** | Fetches Reddit posts via `old.reddit.com` JSON API. No Reddit API credentials needed. | Pre-installed on Mac/Linux |
| **python3** | Parses JSON responses from Reddit and Meta APIs | Pre-installed on Mac/Linux |
| **XAI_API_KEY** (optional) | Enables Grok+X gap mining and demand validation via xAI's Agent Tools API. Plugin works without it — just skips X data. | Get from [console.x.ai](https://console.x.ai), then `export XAI_API_KEY="xai-..."` in your shell profile |

**No Reddit API credentials needed.** The plugin uses `old.reddit.com`'s public JSON API via curl — no OAuth, no MCP server, no npm packages.

## Install

```bash
# From GitHub (once published)
claude plugin add github:yourusername/persona-coverage

# Or from a local clone
git clone https://github.com/yourusername/persona-coverage.git
claude plugin add ./persona-coverage
```

If using Grok+X features, set the API key:
```bash
echo 'export XAI_API_KEY="xai-your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```
/persona-coverage:analyze <brand-name>
```

Example:
```
/persona-coverage:analyze Grüns
```

The tool will:
1. Pull all ads from the brand's Meta pages + discover partner/affiliate ads
2. Gemini-verify every ad's visual content
3. Build the coverage matrix
4. Mine Reddit (via curl) and X (via Grok) for gap personas
5. Validate demand for each persona
6. Produce the final brief with confidence levels

## How it works

### Phase 0 — Full Inventory Pull
Pulls ALL active ads (no sampling). Discovers partner/affiliate pages via keyword search.

### Phase 1 — Gemini-Verified Portfolio Analysis
Every ad goes through `meta-get-ad` → `analyze-creatives` (Gemini). Classification is from what Gemini sees in the video, not from format tags. The format tag "DCO" does not tell you what's inside carousel cards.

### Phase 2 — Gap Mining
Reddit: searches via `curl old.reddit.com/.json` — real posts, real quotes, no fabrication.
X: searches via `scripts/grok-x-research.sh` using xAI's Agent Tools API (if XAI_API_KEY set).

### Phase 2.5 — Demand Validation
Every persona (existing + gap) is validated against X conversation volume via Grok. Personas rated HIGH/MEDIUM/LOW signal.

### Phase 3 — Synthesis
Final brief with confidence levels: verified (Gemini/countable) vs estimated vs inferred.

## Lessons learned

This plugin was built and stress-tested through a live audit of Grüns (greens gummy supplement, 438 ads). Key failure modes discovered and fixed:

1. **Never classify from metadata alone.** DCO format tags hide UGC creator videos inside carousel cards.
2. **Never sample.** A 45-ad sample of a 438-ad portfolio missed entire Macros.
3. **Never fabricate quotes.** If data sources are unavailable, report it — don't generate synthetic quotes.
4. **Never make "zero" claims without 100% Gemini verification.**
5. **Always check the partner layer.** ~23% of a brand's ecosystem can run through affiliate pages.
6. **Always validate demand.** Gap personas from Reddit/X may have no real Meta audience.
7. **State confidence levels on every claim.**

## File structure

```
persona-coverage/
├── .claude-plugin/plugin.json     # Plugin manifest
├── .mcp.json                      # MCP config (empty — no external MCP needed)
├── commands/
│   └── analyze.md                 # Main orchestrator command
├── agents/
│   ├── creative-portfolio-analyzer.md  # Gemini-verified ad classification
│   ├── reddit-persona-miner.md         # Reddit gap mining (curl-based)
│   ├── grok-x-miner.md                # X/Twitter gap mining (xAI API)
│   ├── dtc-strategist-reviewer.md      # QA review loop
│   └── coverage-synthesizer.md         # Final brief synthesis
├── skills/
│   └── persona-coverage-methodology/
│       ├── SKILL.md                    # Core methodology + lessons learned
│       └── references/                 # DTC creative strategy frameworks
├── scripts/
│   ├── grok-x-research.sh            # Grok+X search script
│   └── reddit-verify.sh              # Reddit post verification script
└── README.md
```
