.PHONY: help init lint test docs clean install-tools validate fmt

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize OpenTofu and install pre-commit hooks
	@echo "Initializing OpenTofu..."
	@tofu init
	@echo "Installing pre-commit hooks..."
	@pre-commit install || echo "pre-commit not installed. Run 'make install-tools' first."

install-tools: ## Install required development tools
	@echo "Installing development tools..."
	@which pre-commit > /dev/null || pip install pre-commit
	@which terraform-docs > /dev/null || go install github.com/terraform-docs/terraform-docs@latest
	@which tflint > /dev/null || (curl -L "https://github.com/terraform-linters/tflint/releases/download/v0.50.3/tflint_linux_amd64.zip" -o tflint.zip && unzip -o tflint.zip && sudo mv tflint /usr/local/bin/ && rm tflint.zip)
	@echo "Installing Go dependencies for testing..."
	@cd test && go mod download

fmt: ## Format OpenTofu/Terraform files
	@echo "Formatting OpenTofu/Terraform files..."
	@tofu fmt -recursive .

validate: ## Validate OpenTofu configuration
	@echo "Validating OpenTofu configuration..."
	@tofu init -backend=false
	@tofu validate
	@echo "Running tflint..."
	@tflint --init || true
	@tflint

lint: fmt validate ## Run all linting checks (fmt + validate)
	@echo "Running pre-commit hooks..."
	@pre-commit run --all-files || true

test: ## Run Terratest suite
	@echo "Running Terratest suite..."
	@cd test && go test -v -timeout 60m

docs: ## Generate documentation with terraform-docs
	@echo "Generating documentation..."
	@docker run --rm --volume "$$(pwd):/terraform-docs" -u $$(id -u) quay.io/terraform-docs/terraform-docs:latest markdown /terraform-docs --output-file README.md

clean: ## Clean up temporary files and directories
	@echo "Cleaning up..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "terraform.tfstate*" -exec rm -f {} + 2>/dev/null || true

ci: install-tools lint test ## Run CI pipeline locally
	@echo "CI pipeline completed successfully!"
