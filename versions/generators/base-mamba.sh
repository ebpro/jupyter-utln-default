#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions (all to stderr)
log_info() { echo -e "${GREEN}INFO: $1${NC}" >&2; }
log_warn() { echo -e "${YELLOW}WARN: $1${NC}" >&2; }
log_error() { echo -e "${RED}ERROR: $1${NC}" >&2; }

# Check Mamba availability
check_mamba() {
    if ! command -v mamba &> /dev/null; then
        log_error "Mamba is not installed"
        return 1
    fi
    return 0
}

# Generate Mamba information
generate_mamba_info() {
    # Print Markdown to stdout
    {
        echo "## Mamba Environment"
        echo
        echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        
        echo "### System Information"
        echo
        echo "**Mamba Version:**"
        mamba --version | sed 's/^/  * /'
        echo
        echo "**Python Version:**"
        echo "  * $(python --version 2>&1)"
        echo
        
        echo "### Installed Packages"
        echo
        echo "| Source | Package | Version | Build |"
        echo "|:-------|:--------|:--------|:------|"
        mamba list 2>/dev/null | \
            grep -v "^#" | \
            awk '{printf "| %s | %s | %s | %s |\n", $4, $1, $2, $3}' | \
            sort
        
        echo
        echo "### Environment Information"
        echo
        echo "\`\`\`"
        mamba info
        echo "\`\`\`"
    }
}

# Main execution
main() {
    if ! check_mamba; then
        exit 1
    fi
    generate_mamba_info
}

# Run main function
main