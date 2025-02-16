#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echoerr() { echo "$@" 1>&2; }

# Logging functions
log_info() { echoerr -e "${GREEN}INFO: $1${NC}"; }
log_warn() { echoerr -e "${YELLOW}WARN: $1${NC}"; }
log_error() { echoerr -e "${RED}ERROR: $1${NC}" >&2; }

# Check LaTeX availability
check_latex() {
    if ! command -v tlmgr &> /dev/null; then
        log_error "TeX Live Manager (tlmgr) is not installed"
        return 1
    fi
    return 0
}

# Generate LaTeX information
generate_latex_info() {
        echo "## LaTeX Environment"
        echo
        echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        
        echo "### TeX Live Manager Version"
        echo
        echo "\`\`\`"
        tlmgr --version
        echo "\`\`\`"
        echo
        
        echo "### Installed Packages"
        echo
        echo "| Package | Description |"
        echo "|---------|:------------|"
        tlmgr list --only-installed | \
            sed -n 's/^i \([^:]*\):\s*\(.*\)/|\1|\2|/p' | \
            sort
        
        echo
        echo "### TeX Live Configuration"
        echo
        echo "\`\`\`"
        tlmgr conf
        echo "\`\`\`"
        
    log_info "LaTeX information generated"
}

# Main execution
main() {
    
    if ! check_latex; then
        exit 1
    fi

    generate_latex_info
}

# Run main function
main