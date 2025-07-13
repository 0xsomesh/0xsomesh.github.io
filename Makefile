# Jekyll Blog Makefile
# Author: 0xsomesh

.PHONY: help install serve build clean deploy new-post new-project lint check

# Default target
help:
	@echo "Available commands:"
	@echo "  make install     - Install dependencies (bundle install)"
	@echo "  make serve       - Serve the site locally with live reload"
	@echo "  make build       - Build the site for production"
	@echo "  make clean       - Clean generated files"
	@echo "  make deploy      - Build and deploy to GitHub Pages"
	@echo "  make new-post    - Create a new blog post (requires TITLE)"
	@echo "  make new-project - Create a new project post (requires TITLE)"
	@echo "  make lint        - Check for common issues"
	@echo "  make check       - Run all checks and build"

# Install dependencies
install:
	@echo "Installing Jekyll dependencies..."
	bundle install

# Serve locally with live reload
serve:
	@echo "Starting Jekyll development server..."
	bundle exec jekyll serve --livereload --drafts

# Build for production
build:
	@echo "Building Jekyll site for production..."
	bundle exec jekyll build

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	bundle exec jekyll clean
	rm -rf .sass-cache/

# Deploy to GitHub Pages
deploy: clean build
	@echo "Deploying to GitHub Pages..."
	git add .
	git commit -m "Deploy site updates 🚀"
	git push origin main

# Create new blog post
new-post:
	@if [ -z "$(TITLE)" ]; then \
		echo "Usage: make new-post TITLE='Your Post Title'"; \
		exit 1; \
	fi
	@DATE=$$(date +%Y-%m-%d); \
	SLUG=$$(echo "$(TITLE)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	FILE="_posts/$$DATE-$$SLUG.md"; \
	echo "---" > $$FILE; \
	echo "layout: post" >> $$FILE; \
	echo "title:  \"$(TITLE)\"" >> $$FILE; \
	echo "date:   $$DATE 16:08:31 +0530" >> $$FILE; \
	echo "is_post: True" >> $$FILE; \
	echo "---" >> $$FILE; \
	echo "" >> $$FILE; \
	echo "Write your post content here..." >> $$FILE; \
	echo "Created new post: $$FILE"

# Create new project post
new-project:
	@if [ -z "$(TITLE)" ]; then \
		echo "Usage: make new-project TITLE='Your Project Title'"; \
		exit 1; \
	fi
	@DATE=$$(date +%Y-%m-%d); \
	SLUG=$$(echo "$(TITLE)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$$//g'); \
	FILE="_posts/$$DATE-$$SLUG.md"; \
	echo "---" > $$FILE; \
	echo "layout: post" >> $$FILE; \
	echo "title:  \"$(TITLE)\"" >> $$FILE; \
	echo "date:   $$DATE 16:08:31 +0530" >> $$FILE; \
	echo "is_project: True" >> $$FILE; \
	echo "---" >> $$FILE; \
	echo "" >> $$FILE; \
	echo "[GitHub]()" >> $$FILE; \
	echo "[Documentation]()" >> $$FILE; \
	echo "" >> $$FILE; \
	echo "Write your project description here..." >> $$FILE; \
	echo "Created new project: $$FILE"

# Lint and check for common issues
lint:
	@echo "Checking for common issues..."
	@echo "Checking for TODO comments..."
	@grep -r "TODO\|FIXME\|XXX" _posts/ _includes/ || echo "No TODO comments found"
	@echo "Checking for broken internal links..."
	@find _posts/ -name "*.md" -exec grep -l "\[.*\]()" {} \; || echo "No broken internal links found"

# Run all checks
check: lint build
	@echo "All checks completed successfully!"

# Quick development setup
dev: install serve

# Update dependencies
update:
	@echo "Updating Jekyll dependencies..."
	bundle update

# Show site statistics
stats:
	@echo "Site Statistics:"
	@echo "Posts: $$(find _posts/ -name "*.md" | wc -l)"
	@echo "Projects: $$(grep -l "is_project: True" _posts/*.md | wc -l)"
	@echo "Regular posts: $$(grep -l "is_post: True" _posts/*.md | wc -l)"
	@echo "Images: $$(find images/ -type f | wc -l 2>/dev/null || echo 0)"