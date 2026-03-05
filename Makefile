.PHONY: render-single render-all status download help

API_BASE := https://api.screenshots.live

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

render-single: ## Render a single config (FILE=path/to/render.yaml)
	@test -n "$(FILE)" || (echo "Usage: make render-single FILE=examples/single-app/render.yaml" && exit 1)
	@chmod +x scripts/render-single.sh
	./scripts/render-single.sh $(FILE)

render-all: ## Render all whitelabel apps
	@chmod +x scripts/render-all.sh
	./scripts/render-all.sh

status: ## Check render job status (JOB_ID=your-job-id)
	@test -n "$(JOB_ID)" || (echo "Usage: make status JOB_ID=your-job-id" && exit 1)
	@curl -s $(API_BASE)/render/get-render/$(JOB_ID) \
		-H "Authorization: Bearer $(API_KEY)" | jq .

download: ## Download render output (JOB_ID=your-job-id)
	@test -n "$(JOB_ID)" || (echo "Usage: make download JOB_ID=your-job-id" && exit 1)
	@mkdir -p output
	$(eval URL := $(shell curl -s $(API_BASE)/render/get-render/$(JOB_ID) \
		-H "Authorization: Bearer $(API_KEY)" | jq -r '.data.downloadUrl'))
	@curl -s -o output/$(JOB_ID).zip "$(URL)"
	@echo "Downloaded to output/$(JOB_ID).zip"
