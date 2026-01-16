#!/bin/bash
#
# Render individual PDFs for each chapter/subchapter
# PDFs are placed in _book alongside the HTML files
# Uses parallel processing for faster builds
#

# Number of parallel jobs (adjust based on CPU cores)
MAX_JOBS=${MAX_JOBS:-4}

echo "Building individual chapter PDFs (parallel: $MAX_JOBS jobs)..."

# Create _book directories
mkdir -p _book/ch01-foundations
mkdir -p _book/ch02-spectral-theory
mkdir -p _book/ch03-optimization

# Create a temporary directory for isolated rendering
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Copy full project structure to temp (without _quarto.yml)
cp -r assets "$TMPDIR/"
cp -r ch01-foundations "$TMPDIR/"
cp -r ch02-spectral-theory "$TMPDIR/"
cp -r ch03-optimization "$TMPDIR/"
cp _common.qmd "$TMPDIR/"

# Copy _extensions INTO each chapter folder (so quarto finds them)
cp -r _extensions "$TMPDIR/ch01-foundations/_extensions"
cp -r _extensions "$TMPDIR/ch02-spectral-theory/_extensions"
cp -r _extensions "$TMPDIR/ch03-optimization/_extensions"

# Export TMPDIR for use in subshells
export TMPDIR

# Function to render a single qmd to pdf (runs in background)
render_pdf() {
    local qmd_file="$1"
    local output_dir=$(dirname "$qmd_file")
    local basename=$(basename "$qmd_file" .qmd)
    
    echo "  [START] $qmd_file"
    
    # Render in isolated temp directory (no _quarto.yml = no project)
    if (cd "$TMPDIR/$output_dir" && quarto render "$(basename "$qmd_file")" --to pdf 2>/dev/null); then
        # Move PDF to _book directory structure
        if [ -f "$TMPDIR/$output_dir/$basename.pdf" ]; then
            mv "$TMPDIR/$output_dir/$basename.pdf" "_book/$output_dir/$basename.pdf"
            echo "  [DONE]  $qmd_file -> _book/$output_dir/$basename.pdf"
        fi
    else
        echo "  [FAIL]  $qmd_file"
    fi
}

# Export function for use with xargs/parallel
export -f render_pdf

# List of files to render
QMD_FILES=(
    "ch01-foundations/01-vector-spaces.qmd"
    "ch01-foundations/02-linear-maps.qmd"
    "ch02-spectral-theory/01-eigenvalues.qmd"
    "ch02-spectral-theory/02-decompositions.qmd"
    "ch03-optimization/01-convex-optimization.qmd"
)

# Run renders in parallel using xargs
printf '%s\n' "${QMD_FILES[@]}" | xargs -P "$MAX_JOBS" -I {} bash -c 'render_pdf "$@"' _ {}

# Clean up LaTeX auxiliary files from source directories
echo "Cleaning up auxiliary files..."
find . -maxdepth 2 -name "*.aux" -delete 2>/dev/null
find . -maxdepth 2 -name "*.log" -delete 2>/dev/null
find . -maxdepth 2 -name "*.out" -delete 2>/dev/null
find . -maxdepth 2 -name "*.toc" -delete 2>/dev/null
find . -maxdepth 2 -name "*.nav" -delete 2>/dev/null
find . -maxdepth 2 -name "*.snm" -delete 2>/dev/null
find . -maxdepth 2 -name "*.vrb" -delete 2>/dev/null

echo "Done! PDFs are in _book/"
