#!/usr/bin/env bash
set -euo pipefail

# Render screenshots for all whitelabel apps
#
# Usage:
#   ./scripts/render-all.sh
#
# Reads app slugs from examples/multi-app/whitelabel-apps.yaml
# and submits render jobs for each app's config.
#
# Environment:
#   API_KEY — your Screenshots Live API key (required)

API_BASE="https://api.screenshots.live"
APPS_FILE="examples/multi-app/whitelabel-apps.yaml"
CONFIGS_DIR="examples/multi-app/configs"
SCREENSHOTS_DIR="examples/multi-app/screenshots"
OUTPUT_DIR="output"

if [[ -z "${API_KEY:-}" ]]; then
  echo "Error: API_KEY environment variable is not set"
  echo "  export API_KEY=\"sa_live_your-key-here\""
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "Error: yq is required. Install it: brew install yq"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Collect job IDs
declare -A JOBS

echo "=== Submitting render jobs ==="
echo ""

for app in $(yq -r '.apps[].slug' "$APPS_FILE"); do
  CONFIG="${CONFIGS_DIR}/${app}/render.yaml"

  if [[ ! -f "$CONFIG" ]]; then
    echo "Warning: No config found for ${app} at ${CONFIG}, skipping"
    continue
  fi

  # Check if there are screenshots to upload
  SCREENSHOT_DIR="${SCREENSHOTS_DIR}/${app}"
  CURL_ARGS=()

  if [[ -d "$SCREENSHOT_DIR" ]] && ls "$SCREENSHOT_DIR"/*.png &>/dev/null 2>&1; then
    # Multipart: YAML + pictures
    CURL_ARGS=(-s -X POST "${API_BASE}/render/render-with-pictures"
      -H "Authorization: Bearer ${API_KEY}"
      -F "yaml=@${CONFIG}")

    for pic in "$SCREENSHOT_DIR"/*.png; do
      CURL_ARGS+=(-F "pictures=@${pic}")
    done
  else
    # YAML only
    CURL_ARGS=(-s -X POST "${API_BASE}/render/api"
      -H "Authorization: Bearer ${API_KEY}"
      -H "Content-Type: text/yaml"
      --data-binary "@${CONFIG}")
  fi

  RESPONSE=$(curl "${CURL_ARGS[@]}")
  JOB_ID=$(echo "$RESPONSE" | jq -r '.data.jobId // empty')

  if [[ -z "$JOB_ID" ]]; then
    echo "[FAIL] ${app}: $(echo "$RESPONSE" | jq -r '.message // "Unknown error"')"
    continue
  fi

  JOBS["$app"]="$JOB_ID"
  echo "[OK]   ${app}: job ${JOB_ID}"
done

echo ""
echo "=== Waiting for renders to complete ==="
echo ""

# Poll all jobs
PENDING=("${!JOBS[@]}")

while [[ ${#PENDING[@]} -gt 0 ]]; do
  STILL_PENDING=()

  for app in "${PENDING[@]}"; do
    JOB_ID="${JOBS[$app]}"
    STATUS_RESPONSE=$(curl -s "${API_BASE}/render/get-render/${JOB_ID}" \
      -H "Authorization: Bearer ${API_KEY}")

    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.data.status')

    case "$STATUS" in
      Completed)
        DOWNLOAD_URL=$(echo "$STATUS_RESPONSE" | jq -r '.data.downloadUrl')
        OUTPUT_FILE="${OUTPUT_DIR}/${app}.zip"
        curl -s -o "$OUTPUT_FILE" "$DOWNLOAD_URL"
        echo "[DONE] ${app}: saved to ${OUTPUT_FILE}"
        ;;
      Failed)
        ERROR=$(echo "$STATUS_RESPONSE" | jq -r '.data.errorMessage // "Unknown error"')
        echo "[FAIL] ${app}: ${ERROR}"
        ;;
      *)
        STILL_PENDING+=("$app")
        ;;
    esac
  done

  PENDING=("${STILL_PENDING[@]}")

  if [[ ${#PENDING[@]} -gt 0 ]]; then
    echo "       ${#PENDING[@]} job(s) still rendering... waiting 5s"
    sleep 5
  fi
done

echo ""
echo "=== All done ==="
echo "Output files in ${OUTPUT_DIR}/"
ls -lh "$OUTPUT_DIR"/*.zip 2>/dev/null || echo "No output files generated"
