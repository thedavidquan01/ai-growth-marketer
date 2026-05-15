# Entity ID

*Source: extracted from `the-edge-wiki/Concepts/Entity ID.md`.*

## What It Is
Entity ID is **Meta's visual fingerprint of an ad** — the platform's backend identifier for the *creative experience*, distinct from Creative ID (the identifier for an asset uploaded in Meta Ads Manager). If two ads look too similar, especially in the **first 3 seconds**, Meta groups them under the same Entity ID and treats them as the same ad — regardless of having different Creative IDs.

## Why It Matters
Under Andromeda, Entity ID is the actual ranking and learning unit. Consequences:

- **Inherited Entity ID = no fresh start.** A new ad grouped under an existing Entity ID doesn't earn new learning, new audiences, or much reach beyond what its predecessor already had.
- **Headline/copy tweaks don't earn a new Entity ID.** Visual differentiation does.
- **Creative similarity is now a penalty; creative diversity is a reward** — even when bid and budget are identical.

The new creative-effort metric isn't "how many ads did we make" but **"how many Entity IDs did we earn."** You could upload twenty ads that look the same and Meta would see five.

## Key Facts
- Entity ID is Meta's backend visual-fingerprint identifier, distinct from front-end Creative ID
- Grouping is driven primarily by the **first ~3 seconds** of opening visuals
- Two ads with identical product photos on the same background collapse to **one** Entity ID
- Product flat-lay vs human wearing the product in a different setting registers as **different** Entity IDs
- Whitelisted creator-handle posts often earn **unique** Entity IDs even from familiar visuals
- Headline edits, color swaps, layout micro-tweaks, and CTA-copy changes do **not** earn a new Entity ID
- Inside Creative Pillar audits, new-Entity-ID volume sits alongside cold CPMs and unique reach as a primary creative KPI

## How Meta Decides
| Scenario | Entity ID outcome |
|---|---|
| Two identical product photos on a marble background | **Same Entity ID** — Meta sees one ad |
| Product flat-lay vs. human wearing the product in a different setting | **Different Entity IDs** — visually distinct |
| Two creatives that look similar but not identical | **May still be grouped** if Meta's image classifier considers them the same |
| Same creative whitelisted under a creator's handle | Often treated as a **unique Entity ID** |

## How To Earn New Entity IDs (the rule of pairs)
> "Always think in pairs — new setting, new shot type, new thumbnail, new persona. If those change, you'll likely unlock a new Entity ID and, with it, new audiences."

Big-swing iteration moves that earn new Entity IDs:
- Turning a testimonial video into a Reddit-style static
- Swapping the creator/persona
- Changing the format or vehicle (UGC → podcast clip)
- Changing the setting/backdrop
- Changing the opening hook visual

Tweaks that **do not** earn a new Entity ID:
- Headline copy edits
- Color swaps
- Layout micro-tweaks
- New CTA copy

## Application to differentiation review
When reviewing a Reddit-mined gap candidate for "differentiation from current coverage", apply the rule of pairs: does targeting this micro-persona require *at least two* of (new persona, new setting, new shot type, new hook visual, new vehicle)? If only one changes, the resulting ad will inherit the existing Entity ID and not earn new reach.
