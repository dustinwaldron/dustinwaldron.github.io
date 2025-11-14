# Makefile for Hugo site

# BASE_URL ?= https://dustinwaldron.github.io/
BASE_URL ?= http://localhost:1313/

# Default target
.PHONY: all
all: build

# Build the static site into the /public directory
.PHONY: build
build:
	hugo build --minify --baseURL "$(BASE_URL)"

# Run a local development server with live reload
.PHONY: serve
serve:
	hugo server

# Clean up the generated public directory (optional helper)
.PHONY: clean
clean:
	rm -rf public