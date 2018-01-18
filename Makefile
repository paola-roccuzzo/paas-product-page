
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

vendor: # reinstall ruby dependencies
	@which bundle > /dev/null 2>&1 || (echo 'bundler is required to install application dependencies. Install Ruby + bundler' && false)
	bundle install --path vendor/bundle

.PHONY: test
test: vendor ## Run tests
	bundle exec rspec --format doc

.PHONY: dev
dev: vendor ## Run the application locally in development mode
	RESTCLIENT_LOG=stdout bundle exec rackup

.PHONY: clean
clean: ## Clean up
	rm -rf vendor
