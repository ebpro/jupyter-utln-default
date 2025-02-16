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

# Check Docker availability
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi
    return 0
}

# Generate Docker version information
generate_docker_info() {
        echo "## Docker Environment"
        echo
        echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "### Docker Version"
        echo
        docker version --format '**Docker Client**: {{.Client.Version}}\n**Docker Server**: {{.Server.Version}}'
        echo
        echo "### Docker Plugins"
        echo
        echo "| Plugin | Version | ShortDescription |"
        echo "|---------|:--------:|:-----------------|"
        docker info --format '{{json .}}' | \
            jq -r '.ClientInfo.Plugins[] | "| \(.Name) | \(.Version) | \(.ShortDescription) |"' | \
            sort
        echo
        echo "### Build Details"
        echo
        echo "| Component | Value |"
        echo "|-----------|:------|"
        docker version --format \
            "| Git Commit | {{.Client.GitCommit}} |\n\
             | Go Version | {{.Client.GoVersion}} |\n\
             | OS/Arch | {{.Client.Os}}/{{.Client.Arch}} |"

    log_info "Docker information generated in ${OUTPUT_FILE}"
}

# Main execution
main() {
    if ! check_docker; then
        exit 1
    fi

    generate_docker_info
}

# Run main function
main