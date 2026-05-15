#!/usr/bin/env bash
# grok-x-research.sh — Query xAI Grok with x_search tool over X (Twitter)
# Usage: ./grok-x-research.sh "<topic>" [days_back] [max_results]
# Requires: XAI_API_KEY env var, jq, curl

set -euo pipefail

if [[ -z "${XAI_API_KEY:-}" ]]; then
  echo "Error: XAI_API_KEY not set. Get one at https://console.x.ai" >&2
  exit 1
fi

TOPIC="${1:?Usage: $0 \"<topic>\" [days_back] [max_results]}"
DAYS_BACK="${2:-90}"
MAX_RESULTS="${3:-10}"

FROM_DATE=$(date -v-"${DAYS_BACK}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS_BACK} days" +%Y-%m-%d)

PROMPT=$(cat <<EOF
Use the x_search tool to find up to ${MAX_RESULTS} recent posts on X (Twitter)
since ${FROM_DATE} that reveal psychological, emotional, or behavioural pain
points related to this topic:

Topic: ${TOPIC}

Prioritise posts that:
- Reveal surprising or underutilised consumer pain points or desires
- Show clear emotional, psychological, or behavioural insight
- Can translate into problem/solution messaging for paid ads
- Are from real users (not brand accounts) with visible engagement

Return ONLY a JSON object — no markdown fences, no preamble, no commentary —
with this exact shape:

{
  "insights": [
    {
      "tweet_url": "https://x.com/...",
      "tweet_excerpt": "verbatim quote from the post",
      "key_finding": "the core insight in one sentence",
      "statistics": "any quantitative data, or null",
      "layman_summary": "what this means for a general audience",
      "emotional_language": ["verbatim", "emotional", "or", "sensory", "words"],
      "pain_point": "the underlying problem",
      "funnel_stage": "Unaware | Problem Aware | Solution Aware | Product Aware",
      "demographic": "age, gender, lifestyle, psychographic",
      "messaging_hook": "suggested ad angle",
      "why_it_matters": "relevance for paid marketing"
    }
  ]
}

Constraints:
- Only include findings with clear emotional/psychological/behavioural signal
- tweet_excerpt must be a real verbatim quote, not paraphrased
- emotional_language entries must appear verbatim somewhere in the post
- Output must be valid JSON parseable by jq
EOF
)

REQUEST=$(jq -n --arg prompt "$PROMPT" '{
  model: "grok-4.3",
  stream: false,
  input: [{role: "user", content: $prompt}],
  tools: [{type: "x_search"}],
  temperature: 0.3
}')

RAW=$(curl -sS https://api.x.ai/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${XAI_API_KEY}" \
  -d "$REQUEST")

if echo "$RAW" | jq -e '.error' >/dev/null 2>&1; then
  echo "API Error:" >&2
  echo "$RAW" | jq '.error' >&2
  exit 1
fi

# Concatenate all assistant message text segments
TEXT=$(echo "$RAW" | jq -r '
  [.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text]
  | join("\n")
')

# Collect all url_citation annotations across assistant messages
CITATIONS=$(echo "$RAW" | jq -c '
  [.output[]? | select(.type == "message") | .content[]?.annotations[]?
   | select(.type == "url_citation") | .url] | unique
')

# Tool calls Grok actually made (visible into the x_search queries it issued)
TOOL_CALLS=$(echo "$RAW" | jq -c '
  [.output[]? | select(.type == "custom_tool_call")
   | {name: .name, input: (.input | fromjson? // .input)}]
')

USAGE=$(echo "$RAW" | jq -c '.usage // {}')

# Try to parse the assistant text as JSON; on failure, return raw text
PARSED=$(echo "$TEXT" | jq -R -s '. as $t | try fromjson catch {parse_error: "model did not return valid JSON", raw_text: $t}')

jq -n \
  --arg topic "$TOPIC" \
  --arg from_date "$FROM_DATE" \
  --argjson parsed "$PARSED" \
  --argjson citations "$CITATIONS" \
  --argjson tool_calls "$TOOL_CALLS" \
  --argjson usage "$USAGE" \
  '{
    topic: $topic,
    searched_from: $from_date,
    result: $parsed,
    citations: $citations,
    tool_calls: $tool_calls,
    usage: $usage
  }'
