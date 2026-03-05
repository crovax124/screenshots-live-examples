# Screenshots Live — Examples & Starter Kit

Example configs, CI/CD templates, and scripts for [Screenshots Live](https://screenshots.live) — automate App Store & Play Store screenshot generation via API.

## What is Screenshots Live?

A rendering service that composites your raw app screenshots into store-ready frames with device bezels, text overlays, and backgrounds. Design a template once in the browser editor, then render variants for every app/brand/locale via YAML configs and a simple API call.

- **Browser-based template editor** with a growing library of device frames and public templates
- **YAML configs** — override text, images, colors per variant. One-click YAML download from any template.
- **Flexible image handling** — upload images with the request (`picture://`) or reference URLs from your own storage (GCS, S3, etc.)
- **Async rendering** — Rust + Skia pipeline, poll for status or get an email when done
- **ZIP output** — all rendered screenshots bundled and ready to upload to stores

## Quick Start

### 1. Get an API key

Sign up at [screenshots.live](https://screenshots.live) and create an API key in your dashboard.

```bash
export API_KEY="sa_live_your-key-here"
```

### 2. Create or pick a template

Use the browser editor to design your screenshot frame, or pick one from the template library. Then hit **"Download YAML"** to get a pre-filled config with all item IDs ready to go.

### 3. Render

**Option A** — Upload images with the request:

```bash
curl -s -X POST https://api.screenshots.live/render/render-with-pictures \
  -H "Authorization: Bearer $API_KEY" \
  -F "yaml=@examples/single-app/render.yaml" \
  -F "pictures=@your-screenshot.png"
```

**Option B** — Images already hosted (GCS, S3, any URL):

```bash
curl -s -X POST https://api.screenshots.live/render/api \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: text/yaml" \
  --data-binary @examples/single-app/render-with-urls.yaml
```

Both return a job ID. Poll for the result:

```bash
curl -s https://api.screenshots.live/render/get-render/$JOB_ID \
  -H "Authorization: Bearer $API_KEY"
```

When status is `Completed`, `downloadUrl` contains a pre-signed link to your ZIP (valid for 1 hour).

## Repo Structure

```
.
├── examples/
│   ├── single-app/              # Single app render configs
│   │   ├── render.yaml          # Using picture:// uploads
│   │   └── render-with-urls.yaml # Using hosted image URLs
│   └── multi-app/               # Whitelabel multi-app setup
│       ├── whitelabel-apps.yaml # App registry
│       ├── configs/             # Per-app YAML overrides
│       │   ├── app-alpha/
│       │   │   └── render.yaml
│       │   └── app-beta/
│       │       └── render.yaml
│       └── screenshots/         # Per-app raw screenshots
│           ├── app-alpha/
│           └── app-beta/
├── scripts/
│   ├── render-single.sh         # Render one app
│   └── render-all.sh            # Render all whitelabel apps
├── .github/
│   └── workflows/
│       └── render-screenshots.yml  # GitHub Action workflow
└── Makefile                     # Quick commands
```

## Examples

### Single App

See [`examples/single-app/`](examples/single-app/) for basic render configs.

### Multi-App (Whitelabel)

See [`examples/multi-app/`](examples/multi-app/) for a full whitelabel setup with per-app configs and a CI/CD-ready structure. The [`whitelabel-apps.yaml`](examples/multi-app/whitelabel-apps.yaml) file defines all your app variants.

## CI/CD

### Bash Scripts

```bash
# Render a single app
./scripts/render-single.sh examples/single-app/render.yaml

# Render all whitelabel apps
./scripts/render-all.sh
```

### GitHub Actions

The included workflow (`.github/workflows/render-screenshots.yml`) runs on push to `main` when any YAML config changes. Add your API key as a repository secret named `SCREENSHOTS_LIVE_API_KEY`.

## Makefile

```bash
make render-single FILE=examples/single-app/render.yaml
make render-all
make status JOB_ID=your-job-id
make download JOB_ID=your-job-id
```

## Links

- [Screenshots Live](https://screenshots.live)
- [Template Editor](https://screenshots.live/app/templates)

## License

MIT
