#!/usr/bin/env bash
# reddit-verify.sh — Verify a Reddit post exists and return its content
# Usage: ./reddit-verify.sh "<reddit_url>"
# Uses old.reddit.com JSON API (no auth required, browser User-Agent)

set -euo pipefail

URL="${1:?Usage: $0 \"<reddit_url>\"}"

# Convert to old.reddit.com JSON endpoint
JSON_URL=$(echo "$URL" | sed 's|www.reddit.com|old.reddit.com|' | sed 's|/$||').json

RESPONSE=$(curl -sL \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36" \
  "$JSON_URL" 2>/dev/null)

echo "$RESPONSE" | python3 -c "
import sys, json

raw = sys.stdin.buffer.read()
text = raw.decode('utf-8', errors='replace')

try:
    data = json.loads(text)
    post = data[0]['data']['children'][0]['data']

    result = {
        'verified': True,
        'title': post.get('title', ''),
        'author': post.get('author', ''),
        'subreddit': post.get('subreddit', ''),
        'score': post.get('score', 0),
        'num_comments': post.get('num_comments', 0),
        'created_utc': post.get('created_utc', 0),
        'selftext': post.get('selftext', '')[:1000],
        'url': post.get('url', ''),
        'permalink': 'https://www.reddit.com' + post.get('permalink', '')
    }

    # Also get top 3 comments if available
    if len(data) > 1:
        comments = data[1]['data']['children'][:3]
        result['top_comments'] = []
        for c in comments:
            if c['kind'] == 't1':
                cd = c['data']
                result['top_comments'].append({
                    'author': cd.get('author', ''),
                    'score': cd.get('score', 0),
                    'body': cd.get('body', '')[:500]
                })

    print(json.dumps(result, indent=2, ensure_ascii=False))

except Exception as e:
    print(json.dumps({
        'verified': False,
        'error': str(e),
        'raw_length': len(text)
    }, indent=2))
"
