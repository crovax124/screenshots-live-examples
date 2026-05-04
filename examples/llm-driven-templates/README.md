# LLM-driven templates

End-to-end worked example: hand a Screenshots.live API key to an LLM (Claude,
ChatGPT, Cursor, etc.), let it create a template via the public API, and run a
GitHub Actions workflow that renders screenshots on every push.

This example shows the *exact* prompt, the *exact* curl that produces a
valid template, the resulting JSON, and the workflow file. Drop these into
your own repo and adapt.

## What you need

- A Screenshots.live API key (begins with `sa_live_`). Create one in the
  dashboard under "API access" and store it as a secret.
- A GitHub repo with Actions enabled.
- Any LLM tool — Claude, ChatGPT, Cursor, Continue, Aider — that lets you
  set a system prompt.

## Files in this folder

| File | Purpose |
| --- | --- |
| [`prompt.md`](./prompt.md) | The system prompt verbatim. Paste into your LLM. |
| [`create-template.sh`](./create-template.sh) | One-shot bash that POSTs the template + items. |
| [`expected-template.json`](./expected-template.json) | Known-good payload that validates against `/schema/templates.json`. |
| [`.github/workflows/screenshots.yml`](./.github/workflows/screenshots.yml) | Production-ready CI/CD workflow. |

## The schema URLs an LLM should fetch

- Template JSON Schema: <https://api.screenshots.live/schema/templates.json>
- Full OpenAPI spec: <https://api.screenshots.live/schema/openapi.json>

Neither requires authentication.

## How to run this example

1. Export your API key:

   ```sh
   export SCREENSHOTS_LIVE_API_KEY=sa_live_<your-key>
   ```

2. Run the bash script. It creates the template and adds three items, then
   prints the new `templateId`:

   ```sh
   bash create-template.sh
   ```

3. Copy the printed `templateId` into your repository variables as
   `SCREENSHOTS_TEMPLATE_ID`, and add `SCREENSHOTS_LIVE_API_KEY` as a
   repository secret.

4. Copy `.github/workflows/screenshots.yml` to your repo. Push. Watch the
   Actions tab — the workflow renders, retries on transient failures, and
   uploads the result as an artifact you can download.

## Letting the LLM do the work

Most teams won't run `create-template.sh` by hand. They'll paste
[`prompt.md`](./prompt.md) into Claude or ChatGPT, then say things like:

> "I have a fitness app. Three mobile screens: the home dashboard, the
> workout-tracker, and the achievement screen. Use a blue gradient
> background, white headlines, and an iPhone 15 Pro device frame. Build the
> template and give me a CI/CD workflow."

The LLM will fetch `schema/templates.json`, produce a payload structurally
identical to [`expected-template.json`](./expected-template.json), POST it,
and emit the workflow file. That's the whole loop.

## References

- Public guide: <https://screenshots.live/en/build-with-ai>
- llms.txt: <https://screenshots.live/llms.txt>
- llms-full.txt: <https://screenshots.live/llms-full.txt>
- GitHub Action: <https://github.com/screenshots-live/render-screenshots-action>
