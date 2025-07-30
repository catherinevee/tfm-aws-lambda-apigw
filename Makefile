.PHONY: help init plan apply destroy validate fmt lint clean test examples

# Default target
help:
	@echo "Available commands:"
	@echo "  init      - Initialize Terraform"
	@echo "  plan      - Show Terraform plan"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform resources"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform code"
	@echo "  lint      - Lint Terraform code with tflint"
	@echo "  clean     - Clean up temporary files"
	@echo "  test      - Run tests"
	@echo "  examples  - Deploy examples"

# Initialize Terraform
init:
	terraform init

# Show Terraform plan
plan:
	terraform plan

# Apply Terraform changes
apply:
	terraform apply

# Destroy Terraform resources
destroy:
	terraform destroy

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform code
fmt:
	terraform fmt -recursive

# Lint Terraform code (requires tflint)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint; \
	else \
		echo "tflint not found. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"; \
	fi

# Clean up temporary files
clean:
	rm -rf .terraform
	rm -rf .terraform.lock.hcl
	rm -f *.tfstate
	rm -f *.tfstate.backup
	rm -f lambda_function.zip
	find . -name "*.zip" -delete
	find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true

# Run tests
test:
	@echo "Running Terraform validation..."
	terraform validate
	@echo "Running Terraform format check..."
	terraform fmt -check -recursive
	@echo "All tests passed!"

# Deploy examples
examples:
	@echo "Deploying basic example..."
	cd examples/basic && terraform init && terraform plan
	@echo "Deploying advanced example..."
	cd examples/advanced && terraform init && terraform plan

# Install development dependencies
install-dev:
	@echo "Installing development dependencies..."
	@if command -v go >/dev/null 2>&1; then \
		go install github.com/terraform-linters/tflint/cmd/tflint@latest; \
	else \
		echo "Go not found. Please install Go to use tflint."; \
	fi

# Security scan (requires terrascan)
security-scan:
	@if command -v terrascan >/dev/null 2>&1; then \
		terrascan scan -i terraform; \
	else \
		echo "terrascan not found. Install with: go install github.com/tenable/terrascan/cmd/terrascan@latest"; \
	fi

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > README.md.tmp; \
		echo "Documentation generated in README.md.tmp"; \
	else \
		echo "terraform-docs not found. Install with: go install github.com/terraform-docs/terraform-docs/cmd/terraform-docs@latest"; \
	fi

# Pre-commit checks
pre-commit: fmt validate lint test
	@echo "Pre-commit checks completed successfully!"

# Setup development environment
setup: install-dev
	@echo "Development environment setup complete!"
	@echo "Available commands:"
	@echo "  make help      - Show this help"
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Show Terraform plan"
	@echo "  make apply     - Apply Terraform changes"
	@echo "  make validate  - Validate Terraform configuration"
	@echo "  make fmt       - Format Terraform code"
	@echo "  make lint      - Lint Terraform code"
	@echo "  make test      - Run all tests"
	@echo "  make clean     - Clean up temporary files" 