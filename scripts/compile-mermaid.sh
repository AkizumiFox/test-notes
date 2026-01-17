#!/bin/bash
# Compile all mermaid-src blocks from qmd files to SVG
# SVG files are stored in _mermaid-cache/ with ID-based filenames

set -e

CACHE_DIR="_mermaid-cache"
mkdir -p "$CACHE_DIR"

# Check if mmdc is available
if ! command -v mmdc &> /dev/null; then
    echo "Installing mermaid-cli..."
    npm install -g @mermaid-js/mermaid-cli
fi

echo "Compiling Mermaid diagrams..."

# Find all qmd files and extract mermaid-src blocks with their IDs
for qmd in $(find src -name "*.qmd" 2>/dev/null); do
    # Extract mermaid-src blocks with IDs using awk
    awk '
    /^```\{\.mermaid-src/ { 
        in_mermaid=1
        content=""
        # Extract ID from the line (e.g., ```{.mermaid-src #my-id})
        id=""
        if (match($0, /#([a-zA-Z0-9_-]+)/)) {
            id=substr($0, RSTART+1, RLENGTH-1)
        }
        next 
    }
    /^```$/ && in_mermaid { 
        in_mermaid=0
        # Print ID and content
        print "ID:" id
        print content
        print "---MERMAID_BLOCK_END---"
        next 
    }
    in_mermaid { 
        content = content $0 "\n"
    }
    ' "$qmd" | {
        mermaid_content=""
        mermaid_id=""
        while IFS= read -r line; do
            if [[ "$line" == ID:* ]]; then
                mermaid_id="${line#ID:}"
            elif [ "$line" = "---MERMAID_BLOCK_END---" ]; then
                if [ -n "$mermaid_content" ]; then
                    # Use ID as filename, or generate hash if no ID
                    if [ -n "$mermaid_id" ]; then
                        svg_file="$CACHE_DIR/${mermaid_id}.svg"
                    else
                        hash=$(echo -n "$mermaid_content" | shasum -a 1 | cut -c1-8)
                        svg_file="$CACHE_DIR/${hash}.svg"
                    fi
                    
                    echo "  Compiling: $(basename "$svg_file") (from $qmd)"
                    # Write content to temp file
                    tmp_file=$(mktemp)
                    echo "$mermaid_content" > "$tmp_file"
                    # Compile to SVG
                    mmdc -i "$tmp_file" -o "$svg_file" -b transparent 2>/dev/null || echo "    Warning: failed to compile"
                    rm -f "$tmp_file"
                fi
                mermaid_content=""
                mermaid_id=""
            else
                mermaid_content="${mermaid_content}${line}
"
            fi
        done
    }
done

echo ""
echo "Done! SVGs are in $CACHE_DIR/"
ls -la "$CACHE_DIR/" 2>/dev/null || true
echo ""
echo "Commit _mermaid-cache/ to use pre-compiled diagrams in CI."
