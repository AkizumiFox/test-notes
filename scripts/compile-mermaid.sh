#!/bin/bash
# Compile all mermaid blocks from qmd files to SVG
# SVG files are stored in _mermaid-cache/ with content-hash filenames

set -e

CACHE_DIR="_mermaid-cache"
mkdir -p "$CACHE_DIR"

# Check if mmdc is available
if ! command -v mmdc &> /dev/null; then
    echo "Installing mermaid-cli..."
    npm install -g @mermaid-js/mermaid-cli
fi

echo "Compiling Mermaid diagrams..."

# Find all qmd files and extract mermaid blocks
for qmd in $(find src -name "*.qmd" 2>/dev/null); do
    # Extract mermaid blocks using awk
    awk '
    /^```\{mermaid\}/ { in_mermaid=1; content=""; next }
    /^```$/ && in_mermaid { 
        in_mermaid=0
        # Print the content (will be processed by while loop)
        print content
        print "---MERMAID_BLOCK_END---"
        next 
    }
    in_mermaid { 
        # Skip mermaid options (lines starting with %%|)
        if (!/^%%\|/) {
            content = content $0 "\n"
        }
    }
    ' "$qmd" | while IFS= read -r line; do
        if [ "$line" = "---MERMAID_BLOCK_END---" ]; then
            if [ -n "$mermaid_content" ]; then
                # Compute hash of content
                hash=$(echo -n "$mermaid_content" | shasum -a 1 | cut -c1-8)
                svg_file="$CACHE_DIR/${hash}.svg"
                
                if [ ! -f "$svg_file" ]; then
                    echo "  Compiling: $hash.svg"
                    # Write content to temp file
                    tmp_file=$(mktemp)
                    echo "$mermaid_content" > "$tmp_file"
                    # Compile to SVG
                    mmdc -i "$tmp_file" -o "$svg_file" -b transparent 2>/dev/null || echo "    Warning: failed to compile $hash"
                    rm -f "$tmp_file"
                else
                    echo "  Cached: $hash.svg"
                fi
            fi
            mermaid_content=""
        else
            mermaid_content="${mermaid_content}${line}
"
        fi
    done
done

echo "Done! SVGs are in $CACHE_DIR/"
echo "Commit this directory to use pre-compiled diagrams in CI."
