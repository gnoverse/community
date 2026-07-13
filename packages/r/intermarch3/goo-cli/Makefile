.PHONY: build install test clean fmt lint help

# Binary name
BINARY_NAME=goo
BUILD_DIR=build

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOINSTALL=$(GOCMD) install
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOFMT=$(GOCMD) fmt

# Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/goo
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Install the binary to $GOPATH/bin
install:
	@echo "Installing $(BINARY_NAME)..."
	$(GOINSTALL) ./cmd/goo
	@echo "Install complete!"

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) ./...
	@echo "Format complete!"

# Lint code (requires golangci-lint)
lint:
	@echo "Linting code..."
	@if command -v golangci-lint > /dev/null; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed. Install it from https://golangci-lint.run/"; \
	fi

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOGET) -v ./...
	@echo "Dependencies downloaded!"

# Run the CLI (for testing)
run:
	@$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/goo
	@./$(BUILD_DIR)/$(BINARY_NAME)

# Show help
help:
	@echo "Available targets:"
	@echo "  build      - Build the binary"
	@echo "  install    - Install the binary to \$$GOPATH/bin"
	@echo "  test       - Run tests"
	@echo "  clean      - Clean build artifacts"
	@echo "  fmt        - Format code"
	@echo "  lint       - Lint code (requires golangci-lint)"
	@echo "  deps       - Download dependencies"
	@echo "  run        - Build and run the CLI"
	@echo "  help       - Show this help message"
