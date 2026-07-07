# Makefile for EvoFox Ronin Controller
# Simplified build commands for the Swift Package Manager project

.PHONY: build run clean preview format help

# Default target
all: build

# Build the project
build:
	swift build

# Run the app (requires macOS 13+)
run:
	swift run

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Open in Xcode (requires Xcode 15+)
xcode:
	open Package.swift

# Format Swift files (requires swift-format)
format:
	find Sources -name "*.swift" -exec swift-format -i {} \;

# Show help
help:
	@echo "EvoFox Ronin Controller - Build Commands"
	@echo "========================================"
	@echo "  make build   - Build the project with SPM"
	@echo "  make run     - Build and run the app"
	@echo "  make clean   - Remove build artifacts"
	@echo "  make xcode   - Open project in Xcode"
	@echo "  make format  - Format all Swift files"
	@echo "  make help    - Show this help message"
