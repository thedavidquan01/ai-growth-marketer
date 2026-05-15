---
description: Analyze a brand's ad portfolio for three-layer persona coverage (Macro → Micro → Vehicle) and surface gap opportunities from Reddit (and future research sources), with recursive DTC strategist QA.
argument-hint: <brand-name>
allowed-tools: Task, Read
---

# /persona-coverage:analyze

Run the full persona-coverage analysis for the brand named in `$ARGUMENTS`.

## Pre-flight

If `$ARGUMENTS` is empty, ask the user which brand to analyze and stop. Otherwise treat the entire argument string as the brand name (it may contain spaces).

Read the methodology skill once at the start so you have the full workflow + reference index in context:

```
Read: skills/persona-coverage-methodology/SKILL.md
```

## Workflow

Execute these phases sequentially. The strategist review loops within Phase 1 and Phase 2 are mandatory — do not skip them.

### Phase 0 — Full Inventory Pull (no sampling)

Before spawning the analyzer, pull the complete ad inventory:

1. Use `resolve-company` to get the brand's page ID(s).
2. Pull ALL active ads from each page with `meta-search-ads` using `fetch_all: true`, `sort_by: total_impressions`.
3. Run a **keyword search** for the brand name to discover partner/whitelisted/affiliate ads on other pages.
4. Report the total ad count to the user: "Found N owned ads + M partner ads across P pages."

This data feeds into Phase 1. The analyzer must process ALL ads, not a sample.

### Phase 1 — Portfolio Analysis (with review loop)

1. Spawn the `creative-portfolio-analyzer` agent. Pass the brand name AND the full inventory data. The analyzer must Gemini-verify every ad's visual content — metadata-only classification is not acceptable.
2. Spawn the `dtc-strategist-reviewer` agent. Pass it:
   - Phase tag: `phase-1-portfolio`
   - The full Phase 1 output
   - Brand name
3. The reviewer returns either `SIGNED_OFF` or a structured critique with revision asks.
4. If `SIGNED_OFF`: proceed to Phase 2.
5. If critique: spawn `creative-portfolio-analyzer` again with the prior output + critique + instruction to revise. Then loop back to step 2.
6. **Escape hatch**: if the strategist returns the same critique twice in a row unchanged, stop the loop, flag the unresolved critique as a caveat in the final output, and proceed to Phase 2 with the latest version.

Tell the user concisely each round: "Phase 1 round N — reviewer requested revisions on [topic]". Don't dump full agent output to the user mid-loop.

### Phase 2 — Gap Mining (with review loop)

This phase runs all active gap-mining agents **in parallel** against the signed-off Phase 1 profile. Currently active:

- `reddit-persona-miner` — Reddit (always runs)
- `grok-x-miner` — X via xAI Grok (runs if `XAI_API_KEY` is set; otherwise skipped with a note in the final output)

Future pillars (`review-miner`, `tiktok-comment-miner`) plug into the same shape when built. The strategist rubric applies uniformly to all sources.

Pre-flight before spawning miners:

```bash
[ -n "$XAI_API_KEY" ] && echo "grok-x: enabled" || echo "grok-x: skipped (no XAI_API_KEY)"
```

If `XAI_API_KEY` is missing, do not spawn `grok-x-miner`; note in the final synthesizer input that Phase 2 ran Reddit-only.

For each active miner, run this loop in parallel with the others:

1. Spawn the miner agent. Pass it:
   - Brand name
   - The signed-off Phase 1 portfolio profile (so it knows what is *already* covered at the Macro × Micro × Vehicle level)
2. Spawn the `dtc-strategist-reviewer` agent. Pass:
   - Phase tag: `phase-2-<source>` (e.g. `phase-2-reddit`, `phase-2-grok-x`)
   - The miner's output
   - Brand name
   - The Phase 1 portfolio profile (for "differentiation from current coverage" check)
3. Same loop logic and same escape hatch as Phase 1.

Tell the user concisely which sources are active at the start of Phase 2 (e.g. "Phase 2 mining: Reddit + Grok+X in parallel" or "Phase 2 mining: Reddit only — XAI_API_KEY not set, Grok+X skipped").

### Phase 2.5 — Demand Validation

Spawn the `demand-validator` agent. Pass it:
- All existing Macros from the signed-off Phase 1 profile
- All gap candidates from the signed-off Phase 2 miner outputs
- Brand name and product category

The validator:
1. Runs `scripts/grok-x-research.sh` for each persona to check X conversation volume
2. Verifies every Reddit quote via `scripts/reddit-verify.sh`
3. Rates each persona HIGH / MEDIUM / LOW demand signal
4. Flags anomalies (existing Macros with weak signal, gap candidates with strong signal)

No strategist review loop on this phase — it's a verification step, not creative research. Pass the validator's output directly to Phase 3.

### Phase 3 — Synthesis

Spawn the `coverage-synthesizer` agent. Pass it:
- Brand name
- Signed-off Phase 1 portfolio profile (three-layer coverage breakdown) with Gemini verification rates
- All signed-off Phase 2 miner outputs (one per active source) with verified quotes
- Demand validation results from Phase 2.5 (signal strength per persona)
- Round counts and any caveats from all phases / miners
- Confidence level for each claim: "verified" (Gemini-confirmed or countable metadata) vs "estimated" vs "inferred"

The synthesizer merges multi-source gaps (flagging triangulated ones), renders the final Macro → Micro → Vehicle brief in chat. Every claim in the output must carry its confidence level. That is the deliverable.

## What to surface to the user during the run

Keep updates terse. Surface only:
- Each phase start ("Pulling portfolio for <brand>…", "Mining Reddit for gaps…")
- Each review round's outcome ("Phase 1 round 2 — strategist signed off" or "Phase 1 round 2 — critique on persona specificity, re-running analyzer")
- The escape hatch trigger if it fires
- The final synthesizer output

Do not dump intermediate agent outputs unless the user asks.
