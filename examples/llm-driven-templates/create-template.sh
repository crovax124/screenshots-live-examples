#!/usr/bin/env bash
# Create a Screenshots.live template + items from the command line.
# Mirrors what an LLM agent would emit. Requires SCREENSHOTS_LIVE_API_KEY in env.

set -euo pipefail

API_BASE="${SCREENSHOTS_LIVE_API_BASE:-https://api.screenshots.live}"

if [ -z "${SCREENSHOTS_LIVE_API_KEY:-}" ]; then
  echo "Error: SCREENSHOTS_LIVE_API_KEY is not set" >&2
  echo "Export it: export SCREENSHOTS_LIVE_API_KEY=sa_live_..." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required (brew install jq)" >&2
  exit 1
fi

echo "→ Creating template..."
TEMPLATE_RESPONSE=$(curl -fsS -X POST "${API_BASE}/templates" \
  -H "Authorization: Bearer ${SCREENSHOTS_LIVE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "LLM-driven example — fitness app",
    "screenSizeCategory": "Mobile",
    "screenCount": 3
  }')

TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | jq -r '.data.id')
echo "  templateId = ${TEMPLATE_ID}"

echo "→ Adding gradient background..."
curl -fsS -X POST "${API_BASE}/templates/${TEMPLATE_ID}/items" \
  -H "Authorization: Bearer ${SCREENSHOTS_LIVE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CanvasBackground",
    "x": 0,
    "y": 0,
    "zIndex": 0,
    "properties": {
      "fill": "linear-gradient(180deg, #1E3A8A 0%, #3B82F6 100%)"
    }
  }' >/dev/null

echo "→ Adding headline..."
curl -fsS -X POST "${API_BASE}/templates/${TEMPLATE_ID}/items" \
  -H "Authorization: Bearer ${SCREENSHOTS_LIVE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "Text",
    "x": 80,
    "y": 120,
    "zIndex": 10,
    "properties": {
      "text": "Track every workout",
      "fontSize": 64,
      "fontWeight": "bold",
      "color": "#FFFFFF",
      "textAlign": "left"
    }
  }' >/dev/null

echo "→ Adding device frame placeholder..."
curl -fsS -X POST "${API_BASE}/templates/${TEMPLATE_ID}/items" \
  -H "Authorization: Bearer ${SCREENSHOTS_LIVE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "DeviceFrame",
    "x": 80,
    "y": 380,
    "zIndex": 5,
    "properties": {
      "frameId": "iphone-15-pro",
      "screenshotUrl": ""
    }
  }' >/dev/null

echo
echo "Done."
echo "Set these in your GitHub repo before running the workflow:"
echo "  Repository secret  : SCREENSHOTS_LIVE_API_KEY = (your key)"
echo "  Repository variable: SCREENSHOTS_TEMPLATE_ID  = ${TEMPLATE_ID}"
