#!/usr/bin/env bash
set -euo pipefail

# Render a single app's screenshots
#
# Usage:
#   ./scripts/render-single.sh <yaml-config> [picture1.png picture2.png ...]
#
# Examples:
#   # YAML only (images referenced by URL)
#   ./scripts/render-single.sh examples/single-app/render-with-urls.yaml
#
#   # YAML + picture uploads
#   ./scripts/render-single.sh examples/single-app/render.yaml my-screenshot.png
#
# Environment:
#   API_KEY — your Screenshots Live API key (required)

API_BASE="https://api.screenshots.live"
YAML_FILE="${1:?Usage: render-single.sh <yaml-config> [pictures...]}"
shift
PICTURES=("$@")

if [[ -z "${API_KEY:-}" ]]; then
  echo "Error: API_KEY environment variable is not set"
  echo "  export API_KEY=\"sa_live_your-key-here\""
  exit 1
fi

if [[ ! -f "$YAML_FILE" ]]; then
  echo "Error: YAML file not found: $YAML_FILE"
  exit 1
fi

# Build the curl command
if [[ ${#PICTURES[@]} -gt 0 ]]; then
  # Multipart upload: YAML + pictures
  CURL_ARGS=(-s -X POST "${API_BASE}/render/render-with-pictures"
    -H "Authorization: Bearer ${API_KEY}"
    -F "yaml=@${YAML_FILE}")

  for pic in "${PICTURES[@]}"; do
    if [[ ! -f "$pic" ]]; then
      echo "Error: Picture file not found: $pic"
      exit 1
    fi
    CURL_ARGS+=(-F "pictures=@${pic}")
  done
else
  # YAML only — images referenced by URL
  CURL_ARGS=(-s -X POST "${API_BASE}/render/api"
    -H "Authorization: Bearer ${API_KEY}"
    -H "Content-Type: text/yaml"
    --data-binary "@${YAML_FILE}")
fi

echo "Submitting render job..."
RESPONSE=$(curl "${CURL_ARGS[@]}")
JOB_ID=$(echo "$RESPONSE" | jq -r '.data.jobId // empty')

if [[ -z "$JOB_ID" ]]; then
  echo "Error: Failed to submit render job"
  echo "$RESPONSE" | jq .
  exit 1
fi

echo "Job submitted: $JOB_ID"
echo ""

# Poll for completion
echo "Waiting for render to complete..."
while true; do
  STATUS_RESPONSE=$(curl -s "${API_BASE}/render/get-render/${JOB_ID}" \
    -H "Authorization: Bearer ${API_KEY}")

  STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.data.status')

  case "$STATUS" in
    Completed)
      DOWNLOAD_URL=$(echo "$STATUS_RESPONSE" | jq -r '.data.downloadUrl')
      echo "Render complete!"
      echo ""
      echo "Download URL (valid for 1 hour):"
      echo "  $DOWNLOAD_URL"
      echo ""

      # Download the ZIP
      OUTPUT_FILE="output-${JOB_ID}.zip"
      echo "Downloading to ${OUTPUT_FILE}..."
      curl -s -o "$OUTPUT_FILE" "$DOWNLOAD_URL"
      echo "Done! Saved to $OUTPUT_FILE"
      exit 0
      ;;
    Failed)
      ERROR=$(echo "$STATUS_RESPONSE" | jq -r '.data.errorMessage // "Unknown error"')
      echo "Render failed: $ERROR"
      exit 1
      ;;
    Pending|Active)
      echo "  Status: $STATUS — waiting 5s..."
      sleep 5
      ;;
    *)
      echo "Unexpected status: $STATUS"
      echo "$STATUS_RESPONSE" | jq .
      exit 1
      ;;
  esac
done
