# Makefile for Advanced Linear Algebra Notes
#
# Usage:
#   make all       - Build HTML book + individual chapter PDFs
#   make book      - Build complete book (HTML only)
#   make pdfs      - Build individual chapter PDFs
#   make clean     - Remove all generated files
#   make help      - Show this help message

.PHONY: all book pdfs html preview clean help

# Default target: build HTML and individual PDFs
all: book pdfs

# Build HTML book
book:
	@echo "Building HTML book..."
	quarto render --to html

# Build individual chapter PDFs
pdfs:
	@./render-pdfs.sh

# Preview the book
preview:
	@echo "Starting preview server..."
	quarto preview

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf _book
	rm -rf .quarto
	find . -name "*_files" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -maxdepth 2 \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete 2>/dev/null || true
	@echo "Clean complete."

# Help target
help:
	@echo "Available targets:"
	@echo "  make all      - Build HTML book + individual chapter PDFs"
	@echo "  make book     - Build HTML book only"
	@echo "  make pdfs     - Build individual chapter PDFs"
	@echo "  make preview  - Start live preview server"
	@echo "  make clean    - Remove all generated files"
	@echo "  make help     - Show this help message"
