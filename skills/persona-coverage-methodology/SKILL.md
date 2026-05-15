---
name: persona-coverage-methodology
description: This skill should be used when analyzing a brand's ad portfolio for three-layer persona coverage (Macro → Micro → Vehicle), mapping creative-to-persona gaps across multiple research sources (Reddit, X, reviews, surveys, interviews), or producing a coverage matrix and gap brief. Provides the workflow logic for the persona-coverage plugin and indexes the DTC creative-strategy reference library.
---

# Persona Coverage Methodology

## When to use this skill

Activate when running `/persona-coverage:analyze`, when reviewing a brand's ad-portfolio coverage, when mapping creative output against persona archetypes, or when producing a persona × format × emotion coverage matrix.

This skill defines:

- The **conceptual frame** — the three-layer persona taxonomy that anchors every output.
- The **methodology** for going from raw Ad Library output → coverage matrix → gap mining → final brief.
- The **review rubric** the DTC strategist agent applies at each phase.
- An **index of references** (deep frameworks) under `references/` that the strategist and synthesizer should load on demand.

## Core conceptual frame — the Three-Layer Persona Taxonomy

Every persona output in this plugin — portfolio cluster, candidate gap, synthesized row — must be populated at all three layers:

- **Layer 1 — Macro Persona (WHO)**: the broad named archetype. Specific enough to picture one in your head (not "Women 30+").
- **Layer 2 — Micro Persona (WHY)**: the dominant *desire*, *fear*, and *belief* operating under the Macro. Two Micros under the same Macro yield different briefs.
- **Layer 3 — Creative Vehicle (HOW)**: the format / creator type / shot grammar that delivers the Micro as a distinct Andromeda signal. Same Micro can ship in multiple Vehicles to unlock incremental reach.

Anything missing a layer is incomplete and the strategist must reject it. Full framework + examples in `references/three-layer-persona-taxonomy.md` — load at the start of every agent run.

## Research pillars — public-only scope

The plugin uses **publicly available sources only**, so it functions as a competitive-intel tool on any brand without requiring data-sharing access. Five pillars:

| # | Pillar | Status | Agent / tool |
|---|---|---|---|
| 1 | Ad Library (Meta / TikTok / Google) | ✅ Wired | `creative-portfolio-analyzer` (Ad Library MCP) |
| 2 | Reddit | ✅ Wired | `reddit-persona-miner` (reddit-mcp-buddy MCP OR `curl old.reddit.com/.json` fallback) |
| 3 | Grok + X | ✅ Wired | `grok-x-miner` calling `scripts/grok-x-research.sh` (xAI Agent Tools API; requires `XAI_API_KEY` env var) |
| 4 | Public review mining (category-dependent) | ⬜ Not built | Future `review-miner` — picks the right review surface per brand category (Trustpilot / Amazon / App Store / G2 / Sephora etc.) |
| 5 | TikTok comment mining | ⬜ Not built | Future agent using `mcp__claude_ai_Ad_Library__tiktok-get-comments` |

**Dropped from scope (require private data access):**
- Post-purchase surveys — needs brand's checkout
- AI-powered customer interviews — needs brand's customer list

**Evaluated and dropped (no native public access):**
- YouTube comments — no MCP available, would need YouTube Data API + OAuth
- Search intent (AnswerThePublic / AlsoAsked) — Google Ads MCP gives quantitative volume but not qualitative phrasing

Phase 2 is named "Gap Mining" (source-agnostic). All active miners spawn in parallel and the strategist rubric applies uniformly across sources. Gaps appearing in 2+ pillars are tagged "Triangulated" in synthesis and listed first.

## Core methodology — three-phase loop

### Phase 0 — Full Inventory Pull
Pull ALL active ads from every brand page (not a sample). Use `fetch_all: true` and `sort_by: total_impressions`. Also run a keyword search for the brand name to discover partner/whitelisted/affiliate ads on other pages. Report total ad count before proceeding.

### Phase 1 — Portfolio Analysis (Gemini-verified)
Pull the brand's active and recent creative from the Ad Library MCP. For each ad: use `meta-get-ad` to extract video/image URLs from carousel cards, then run `analyze-creatives` (Gemini) on every media asset. Classify from what Gemini sees — **NEVER from metadata/format tags alone**. The format tag "DCO" does not tell you what's inside the carousel cards. In testing, metadata-only classification labeled ~70% of a portfolio as "brand-produced" when Gemini showed it was UGC creators talking to camera.

Classify across the 9 Creative Diversity dimensions (format, persona on camera, setting, shot type, hook visual, vehicle, emotional zone, identity angle, creative angle) **plus** the three-layer taxonomy (implied Macro persona, Micro persona with desire/fear/belief, Vehicle), **plus** Schwartz awareness stage and best-fit Reiss desire.

Cluster ads first by **Micro** (not Macro) — that's where coverage actually concentrates or thins. Roll up to Macro for the matrix view. Surface empty cells in the Macro × Micro × Vehicle cube as within-portfolio gaps.

Every claim must state its verification level: "Gemini-verified" or "metadata-inferred (unverified)". Never make absolute claims ("zero X across N ads") unless 100% of ads have been Gemini-verified for that dimension.

Output: structured profile including spend concentration, Squint Test result, Entity ID estimate, and three-layer coverage breakdown.

→ Strategist reviews → loop until signed off.

### Phase 2 — Gap Mining (multi-source)
Find Macros, Micros, and Vehicles the portfolio does not address. Active miners run in parallel: `reddit-persona-miner` and `grok-x-miner` (if XAI_API_KEY set).

For each candidate gap, the miner produces a complete three-layer specification: Macro (named archetype), Micro (desire / fear / belief), recommended Vehicles, plus 2–4 verbatim source quotes with permalinks, the implied Reiss desire, the Schwartz awareness stage, and brand-fit reasoning.

**Reddit quote verification:** If the Reddit MCP is unavailable, the miner uses `curl old.reddit.com/.json` as a fallback to fetch real posts. Every Reddit quote must be verified against the actual post content — never use training-data-generated quotes. The verification method (MCP or curl) must be stated in the output.

→ Strategist reviews → loop until signed off.

### Phase 2.5 — Demand Validation (NEW — added from session learnings)

Before synthesis, validate every persona against real audience signals. This prevents recommending personas that look good structurally but have no real audience:

1. For each **existing Macro** from Phase 1: run `scripts/grok-x-research.sh` to check X conversation volume and sentiment.
2. For each **gap candidate** from Phase 2: same Grok validation.
3. For each Reddit-sourced quote: verify via `curl old.reddit.com/{post_path}/.json` that the post exists and the text matches.
4. Rate each persona as **HIGH** (5+ insights/citations), **MEDIUM** (2-4), or **LOW** (0-1) demand signal.
5. Flag LOW-signal personas as "weak demand — test cautiously" so the synthesizer deprioritizes them.

This phase catches two failure modes: (a) gap personas that are intellectually interesting but have no real audience, and (b) existing Macros the brand is investing in despite thin demand.

### Phase 3 — Synthesis
With all phases signed off, produce the coverage matrix + gap brief in chat. Every claim must carry a confidence indicator:
- **Verified**: Gemini-confirmed visual data, or countable metadata (ad counts, LP paths)
- **Estimated**: aggregated from batch-level observations, not precisely counted
- **Inferred**: derived from metadata patterns, not visually confirmed

Structure per the README's "Output" section.

## DTC Strategist Review Rubric

The reviewer is a deeply experienced DTC creative strategist. They check each researcher output against:

**For Phase 1 (Portfolio Analysis):**
1. **Brand-context fidelity** — does the analysis correctly infer the brand's positioning, ICP, and offer category from the ads? Or is it generic?
2. **Three-layer completeness** — every cluster names Macro + Micro (with desire / fear / belief) + Vehicle. No demographic-only Macros, no half-Micros.
3. **Framework rigor** — are personas defined with enough specificity to brief against? Are the 9 Creative Diversity dimensions all assessed?
4. **Coverage logic** — is "coverage" measured by spend share + Entity ID volume, not just ad count? Is the Macro × Micro × Vehicle cube populated with empty-cell findings?
5. **Squint Test applied** — would the portfolio look visually diverse to Meta, or is it 20 versions of the same scene?
6. **Awareness stage mapped** — is each cluster placed on the Schwartz 5-stage spectrum?

**For Phase 2 (Gap Mining):**
1. **Three-layer completeness** — every candidate gap names Macro + Micro (desire / fear / belief) + recommended Vehicles. No layer is optional.
2. **Verbatim verbiage** — are quotes literal, with permalinks, not paraphrased? Do quotes articulate the *belief* or *fear* of the Micro, not just topic affinity?
3. **Brand-fit gating** — is each candidate plausibly addressable by this specific brand's offer? Generic "everyone has anxiety" gaps fail.
4. **Reiss desire mapping** — is each Micro traced to one of the 16 Reiss desires?
5. **Awareness stage** — is the Micro's prospect placed on the Schwartz spectrum so the message angle matches?
6. **Differentiation from current coverage** — does this gap unlock a net-new Macro/Micro/Vehicle combination per the rule of pairs?

The reviewer issues a critique with specific revision asks. The researcher revises. The reviewer reviews again. **No iteration cap** — but a runaway-loop escape hatch fires if the same critique appears twice unchanged: the run ships with the unresolved critique noted as a caveat.

## Reference Index

Load these from `references/` on demand. Do not preload everything — the SKILL.md sets context, references provide depth.

### Core creative-strategy frameworks (extracted from `the-edge-wiki`)

- `creative-strategy.md` — the master skill hub; entry point for the whole framework set.
- `creative-pillar.md` — 5 sub-factors of creative health (Persona Coverage, Messaging Diversity, Volume & Velocity, Format & Vehicle, Concentration & Lifespan). Load when scoring a portfolio.
- `persona-x-format-grid.md` — the canonical N personas × N formats matrix. Load when constructing the coverage matrix.
- `creative-diversity.md` — the 9 visual + messaging diversity dimensions, plus what does NOT count as diversity. Load when classifying ads.
- `volume-and-velocity.md` — the math (Win Rate × Half-Life × Churn × Scenario) for sizing distinct-asset production. Load when interpreting volume signals.
- `testing-hierarchy-pyramid.md` — Explore / Optimise / Scale split for tests. Load when proposing concept briefs.
- `strategic-volume.md` — volume = diversity, not repetition. Load alongside Volume & Velocity.

### Algorithmic-mechanics concepts

- `entity-id.md` — Meta's visual fingerprint; the unit Andromeda actually counts. Load when the analysis uses "new ad" claims.
- `creative-id.md` — the front-end vanity unit; foil for Entity ID.
- `first-3-seconds-rule.md` — opening visuals carry classification weight. Load when assessing hook diversity.
- `soulmate-theory.md` — why diversity matters. Load when explaining coverage logic to the user.
- `squint-test.md` — visual-diversity diagnostic. Load when applying it.

### Psychology / persuasion concepts

- `pain-is-the-pitch.md` — pain articulation > benefit-naming. Load when evaluating the message angle of a gap concept.
- `status-as-universal-driver.md` — most desires resolve to status. Load when mapping Reiss desires.
- `fear-of-loss-vs-desire-for-gain.md` — loss aversion is ~2x stronger than gain-seeking. Load when reviewing message framing.
- `logical-vs-psychological-solutions.md` — psychological reframes often beat logical fixes. Load when generating gap concept briefs.

### Lens frameworks (authored for this plugin)

- `three-layer-persona-taxonomy.md` — **the canonical persona model: Macro → Micro → Vehicle.** Load at the start of every agent run; everything else hangs off this.
- `reiss-16-desires.md` — Steven Reiss's 16 basic motivational desires. Reference for tagging the implied desire on every Micro.
- `schwartz-5-stages.md` — Eugene Schwartz's 5 stages of awareness (Unaware → Most Aware). Reference for placing every Micro on the awareness spectrum.

## Workflow checklist for the orchestrator command

0. **Phase 0 — Full inventory pull.** Resolve brand via `resolve-company`. Pull ALL ads from every page (`fetch_all: true`, `sort_by: total_impressions`). Run keyword search for brand name to find partner/affiliate pages. Report total count.
1. **Phase 1 — Gemini-verified portfolio analysis.** Spawn `creative-portfolio-analyzer` with full inventory. Analyzer must `meta-get-ad` each ad → extract carousel card video/image URLs → `analyze-creatives` (Gemini) on every asset. Classify from Gemini output, not metadata. Loads `three-layer-persona-taxonomy.md` at start.
2. **Phase 1 review.** Spawn `dtc-strategist-reviewer`. Loop revise/review until sign-off (or escape-hatch trigger).
3. **Phase 2 — Gap mining.** Spawn active miners in parallel with signed-off Phase 1 profile: `reddit-persona-miner` (MCP or curl fallback) + `grok-x-miner` (if XAI_API_KEY set). Each produces three-layer candidate gaps with verified quotes.
4. **Phase 2 review.** Spawn `dtc-strategist-reviewer` per source. Loop until sign-off.
5. **Phase 2.5 — Demand validation.** Run `grok-x-research.sh` for each existing Macro AND each gap candidate. Verify Reddit quotes via `scripts/reddit-verify.sh`. Rate each persona HIGH/MEDIUM/LOW.
6. **Phase 3 — Synthesis.** Spawn `coverage-synthesizer` with all signed-off outputs + demand validation + confidence levels. Final deliverable in chat.

## Lessons learned (from Grüns session — May 2026)

These failure modes were discovered during a live audit and must be avoided:

1. **Never classify from metadata alone.** DCO format tags hide UGC creator videos inside carousel cards. "DCO" ≠ "brand-produced." The only way to know what's in an ad is to Gemini-watch it.
2. **Never sample.** A 45-ad sample of a 438-ad portfolio missed entire Macros (male fertility, perimenopause, partner shopper, IBS). Pull everything.
3. **Never fabricate quotes.** If Reddit MCP is unavailable, use `curl old.reddit.com/.json` fallback — never generate synthetic quotes from training data.
4. **Never make "zero" claims without 100% verification.** "Zero male faces across 438 ads" was disproved when Gemini found 18+ distinct males. Absolute claims require absolute verification.
5. **Always check the partner layer.** 23.5% of a brand's ad ecosystem can run through affiliate/whitelisted pages invisible to an owned-page-only pull.
6. **Always validate demand.** Gap personas mined from Reddit/X may have no real audience on Meta. Run Grok x_search to check conversation volume before recommending.
7. **State confidence levels on every claim.** Verified (Gemini/countable) vs. estimated (aggregated) vs. inferred (metadata-derived).

## Output format (synthesizer renders this)

The synthesizer is responsible for the full output template. See `agents/coverage-synthesizer.md` for the canonical structure. Headline shape:

```
# Persona Coverage Analysis: <Brand>

## Brand Context
<synthesized from Phase 1 portfolio>

## Current Coverage (Macro → Micros → Vehicles)
<For each Macro: list its Micros with desire/fear/belief, the Vehicles currently shipping, ad counts, dominant emotional zone, spend share if visible. Flag empty Vehicle cells.>

## Coverage Diagnostics
<Persona concentration, Squint Test, emotional/identity/awareness distributions, Entity ID estimate, empty Macro × Micro × Vehicle cells.>

## Top Gap Opportunities
<Each gap rendered as Macro → Micro (desire/fear/belief) → recommended Vehicles, with verbatim source quotes, Reiss desire, Schwartz stage, brand-fit reasoning, and a concept brief that pulls on the Micro's belief/fear for hook framing.>

## Strategist Sign-Off
<Round counts per phase + caveats.>

## Recommended Next Moves
<3–5 concrete bullets.>
```
