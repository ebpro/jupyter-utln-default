#!/bin/bash

# Save original error handling
#set +e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration marker file
MARKER_FILE="${HOME}/work/CONFIGURATION_DONE"

# Logging functions
log_info() { echo -e "${GREEN}INFO: $1${NC}"; }
log_warn() { echo -e "${YELLOW}WARN: $1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}" >&2; }

# Check if configuration has already been done
if [[ -f "${MARKER_FILE}" ]]; then
    # log_info "Configuration already completed. Skipping startup scripts."
else
    # Execute startup scripts
    if [[ -d "${HOME}/startup-scripts.d" ]]; then
        for script in $(find "${HOME}/startup-scripts.d" -name "*.sh" | sort); do
            if [[ -x "${script}" ]]; then
                log_info "Executing: $(basename "${script}")"
                # Source script in a subshell to isolate failures
                (source "${script}") || log_error "Failed to execute: ${script}"
            fi
        done
        # Create marker file after successful execution
        touch "${MARKER_FILE}"
        log_info "Configuration completed successfully. Created marker file: ${MARKER_FILE}"
    fi
fi

# Restore original shell state
#set -e
