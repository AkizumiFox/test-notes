#!/bin/bash
#
# Render individual PDFs for each chapter/subchapter
# PDFs are placed in _book alongside the HTML files
#

echo "Building individual chapter PDFs..."

# Create _book directories
mkdir -p _book/ch01-foundations
mkdir -p _book/ch02-spectral-theory
mkdir -p _book/ch03-optimization

# Backup _quarto.yml and ensure it's restored on exit
cp _quarto.yml _quarto.yml.bak
trap 'mv _quarto.yml.bak _quarto.yml 2>/dev/null' EXIT

# Remove _quarto.yml temporarily so files render individually
rm _quarto.yml

# Function to render a single qmd to pdf
render_pdf() {
    local qmd_file="$1"
    local output_dir=$(dirname "$qmd_file")
    local basename=$(basename "$qmd_file" .qmd)
    
    echo "  Rendering: $qmd_file"
    
    # Render from the file's directory so includes work
    (cd "$output_dir" && quarto render "$(basename "$qmd_file")" --to pdf 2>/dev/null) || true
    
    # Move PDF to _book directory structure
    if [ -f "$output_dir/$basename.pdf" ]; then
        mv "$output_dir/$basename.pdf" "_book/$output_dir/$basename.pdf"
        echo "    -> _book/$output_dir/$basename.pdf"
    fi
}

# Render all chapter files
for qmd in ch01-foundations/index.qmd ch01-foundations/01-vector-spaces.qmd ch01-foundations/02-linear-maps.qmd \
           ch02-spectral-theory/index.qmd ch02-spectral-theory/01-eigenvalues.qmd ch02-spectral-theory/02-decompositions.qmd \
           ch03-optimization/index.qmd ch03-optimization/01-convex-optimization.qmd; do
    if [ -f "$qmd" ]; then
        render_pdf "$qmd"
    fi
done

echo "Done! PDFs are in _book/"
