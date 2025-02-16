#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echoerr() { echo "$@" 1>&2; }

# Generate markdown table
generate_markdown_table() {
        echo "## APT Packages"
        echo
        echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "| Package | Version | Architecture |"
        echo "|---------|----------|:------------:|"
        
        # Get installed packages and sort them
        apt list --installed 2>/dev/null | \
        grep -v "Listing..." | \
        sort | \
        while IFS='/' read -r package arch version _; do
            # Extract package name and version
            version=${version%% *}  # Remove everything after first space
            echo "| ${package} | ${version} | ${arch} |"
        done
}

# Main execution
main() {
    if ! command -v apt &> /dev/null; then
        echoerr -e "${YELLOW}Warning: apt command not found${NC}"
        exit 1
    fi 

    generate_markdown_table
}

# Run main function
main