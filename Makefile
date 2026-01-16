# Makefile for Advanced Linear Algebra Notes
#
# Features:
#   - Auto-generates chapters list from src/ directory structure
#   - Builds HTML book + full book PDF
#   - Builds individual chapter PDFs with parallel processing
#   - Git integration for easy deployment
#
# Usage:
#   make all       - Build everything (auto-detect chapters, HTML, PDFs)
#   make book      - Build HTML + full book PDF only
#   make pdfs      - Build individual chapter PDFs only
#   make update    - Update _quarto.yml chapters list only
#   make preview   - Start live preview server
#   make deploy    - Build all, commit, and push to GitHub
#   make push      - Just commit and push (no build)
#   make clean     - Remove all generated files
#   make help      - Show this help message

.PHONY: all book pdfs update preview clean help deploy push

# Parallel jobs for individual PDF rendering
MAX_JOBS ?= 4

# =============================================================================
# Main targets
# =============================================================================

# Default: update chapters, build book, build individual PDFs
all: update book pdfs

# Build HTML + full book PDF
book: update
	@echo "Building HTML book + full book PDF..."
	@quarto render
	@echo "Done! HTML at _book/index.html, PDF at _book/Advanced-Linear-Algebra-Notes.pdf"

# Preview the book
preview: update
	@echo "Starting preview server..."
	@quarto preview

# =============================================================================
# Auto-generate chapters list in _quarto.yml
# =============================================================================

update:
	@echo "Auto-detecting chapters from src/..."
	@# Generate the chapters section
	@{ \
		echo "  # AUTO-GENERATED CHAPTERS - Do not edit manually"; \
		echo "  # Run 'make update' to regenerate from src/ directory"; \
		echo "  chapters:"; \
		echo "    - index.qmd"; \
		for part_dir in src/ch[0-9][0-9]-*/; do \
			if [ -d "$$part_dir" ]; then \
				part_index="$${part_dir}index.qmd"; \
				if [ -f "$$part_index" ]; then \
					echo ""; \
					echo "    - part: $$part_index"; \
					echo "      chapters:"; \
					for chapter in $${part_dir}[0-9][0-9]-*.qmd; do \
						if [ -f "$$chapter" ]; then \
							echo "        - $$chapter"; \
						fi; \
					done; \
				fi; \
			fi; \
		done; \
		echo ""; \
	} > .chapters.yml.tmp
	@# Update _quarto.yml by replacing chapters section
	@awk ' \
		BEGIN { in_chapters = 0; printed = 0 } \
		/^  # AUTO-GENERATED CHAPTERS/ { in_chapters = 1; next } \
		/^  chapters:/ && !printed { \
			in_chapters = 1; \
			while ((getline line < ".chapters.yml.tmp") > 0) print line; \
			printed = 1; \
			next \
		} \
		in_chapters && /^[a-z]/ { in_chapters = 0 } \
		in_chapters && /^filters:/ { in_chapters = 0 } \
		!in_chapters { print } \
	' _quarto.yml > _quarto.yml.tmp
	@mv _quarto.yml.tmp _quarto.yml
	@rm -f .chapters.yml.tmp
	@echo "Updated _quarto.yml with $$(find src/ch*-*/ -name '[0-9][0-9]-*.qmd' 2>/dev/null | wc -l | tr -d ' ') chapter files"

# =============================================================================
# Individual chapter PDFs (parallel processing)
# =============================================================================

pdfs:
	@echo "Building individual chapter PDFs (parallel: $(MAX_JOBS) jobs)..."
	@# Create temp directory for isolated rendering
	@RENDER_TMPDIR=$$(mktemp -d); \
	trap 'rm -rf "$$RENDER_TMPDIR"' EXIT; \
	\
	cp -r config "$$RENDER_TMPDIR/"; \
	\
	for dir in src/ch*-*/; do \
		dir_name="$${dir%/}"; \
		mkdir -p "_book/$$dir_name"; \
		mkdir -p "$$RENDER_TMPDIR/$$dir_name"; \
		cp "$$dir_name"/*.qmd "$$RENDER_TMPDIR/$$dir_name/" 2>/dev/null || true; \
		cp -r _extensions "$$RENDER_TMPDIR/$$dir_name/_extensions" 2>/dev/null || true; \
	done; \
	\
	QMD_FILES=$$(find src/ch*-* -name '[0-9][0-9]-*.qmd' 2>/dev/null | sort); \
	echo "Found $$(echo "$$QMD_FILES" | wc -l | tr -d ' ') chapter files"; \
	\
	render_one() { \
		qmd_file="$$1"; \
		tmpdir="$$2"; \
		output_dir=$$(dirname "$$qmd_file"); \
		base=$$(basename "$$qmd_file" .qmd); \
		echo "  [START] $$qmd_file"; \
		if (cd "$$tmpdir/$$output_dir" && quarto render "$$base.qmd" --to pdf --metadata standalone-pdf:true 2>/dev/null); then \
			if [ -f "$$tmpdir/$$output_dir/$$base.pdf" ]; then \
				mv "$$tmpdir/$$output_dir/$$base.pdf" "_book/$$output_dir/$$base.pdf"; \
				echo "  [DONE]  $$qmd_file -> _book/$$output_dir/$$base.pdf"; \
			fi; \
		else \
			echo "  [FAIL]  $$qmd_file"; \
		fi; \
	}; \
	export -f render_one 2>/dev/null || true; \
	\
	for qmd in $$QMD_FILES; do \
		render_one "$$qmd" "$$RENDER_TMPDIR" & \
		if [ $$(jobs -r | wc -l) -ge $(MAX_JOBS) ]; then wait -n 2>/dev/null || wait; fi; \
	done; \
	wait
	@echo "Cleaning up auxiliary files..."
	@find . -maxdepth 4 \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete 2>/dev/null || true
	@echo "Done! PDFs are in _book/"

# =============================================================================
# Git deployment
# =============================================================================

# Commit message - can be overridden: make deploy MSG="your message"
MSG ?= "Update notes - $$(date '+%Y-%m-%d %H:%M')"

# Build everything, commit, and push
deploy: all
	@echo "Deploying to GitHub..."
	@git add -A
	@git commit -m $(MSG) || echo "Nothing to commit"
	@git push
	@echo "Deployed successfully!"

# Just commit and push (no build)
push:
	@echo "Pushing to GitHub..."
	@git add -A
	@git commit -m $(MSG) || echo "Nothing to commit"
	@git push
	@echo "Pushed successfully!"

# =============================================================================
# Cleanup
# =============================================================================

clean:
	@echo "Cleaning generated files..."
	@rm -rf _book
	@rm -rf .quarto
	@find . -name "*_files" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -maxdepth 4 \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete 2>/dev/null || true
	@echo "Clean complete."

# =============================================================================
# Help
# =============================================================================

help:
	@echo "Advanced Linear Algebra Notes - Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Build targets:"
	@echo "  all      - Build everything (update chapters, HTML+PDF, individual PDFs)"
	@echo "  book     - Build HTML book + full book PDF"
	@echo "  pdfs     - Build individual chapter PDFs (parallel processing)"
	@echo "  update   - Auto-update _quarto.yml chapters from src/ directory"
	@echo "  preview  - Start live preview server"
	@echo "  clean    - Remove all generated files"
	@echo ""
	@echo "Git targets:"
	@echo "  deploy   - Build all, then commit and push to GitHub"
	@echo "  push     - Just commit and push (no build)"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy                    # Build and push with auto timestamp"
	@echo "  make deploy MSG=\"Add ch04\"     # Build and push with custom message"
	@echo "  make push MSG=\"Fix typo\"       # Quick push without rebuilding"
	@echo ""
	@echo "Environment variables:"
	@echo "  MAX_JOBS - Number of parallel jobs for PDF rendering (default: 4)"
	@echo "  MSG      - Git commit message (default: auto timestamp)"
	@echo ""
	@echo "Directory structure:"
	@echo "  src/ch01-name/index.qmd     - Part header"
	@echo "  src/ch01-name/01-topic.qmd  - Chapter file"
	@echo "  src/ch02-name/index.qmd     - Next part header"
	@echo "  ..."
