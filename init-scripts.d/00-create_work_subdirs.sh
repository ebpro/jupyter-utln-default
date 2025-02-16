#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}INFO: $1${NC}"; }
log_warn() { echo -e "${YELLOW}WARN: $1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}" >&2; }

# Function to validate directory name
validate_dir_name() {
    local dir=$1

    if [[ "$dir" =~ [[:space:]] ]]; then
        log_error "Directory name cannot contain spaces: '$dir'"
        return 1
    fi
    
    if [[ "$dir" == *".."* ]] || [[ "$dir" == *"/"* ]]; then
        log_error "Directory name cannot contain .. or /: '$dir'"
        return 1
    fi
    return 0
}

# Function to create and link directories
create_and_link_dir() {
    local subdir=$1
    local work_dir="${WORK_DIR:-${HOME}/work}"
    local home_dir="${HOME}"

    # Validate directory name
    if ! validate_dir_name "$subdir"; then
        return 1
    fi

    log_info "Processing directory: ${subdir}"

    # Create work directory if it doesn't exist
    if [[ ! -d "${work_dir}/${subdir}" ]]; then
        mkdir -p "${work_dir}/${subdir}"
        log_info "Created directory: ${work_dir}/${subdir}"
    fi

    # Remove existing symlink or directory
    if [[ -L "${home_dir}/${subdir}" ]]; then
        rm "${home_dir}/${subdir}"
    elif [[ -d "${home_dir}/${subdir}" ]]; then
        log_warn "Directory exists, backing up: ${home_dir}/${subdir}"
        mv "${home_dir}/${subdir}" "${home_dir}/${subdir}.bak"
    fi

    # Create symbolic link
    ln -sf "${work_dir}/${subdir}" "${home_dir}/${subdir}"

    # Set proper permissions
    chmod 750 "${work_dir}/${subdir}"
}

# Process colon-separated list of directories
process_directories() {
    local dirs_list=$1
    local failed=0

    # Convert colon-separated string to array
    IFS=':' read -rA dirs <<< "$dirs_list"

    for dir in "${dirs[@]}"; do
        # Skip empty entries
        [[ -z "$dir" ]] && continue
        
        if ! create_and_link_dir "$dir"; then
            ((failed++))
            log_error "Failed to process directory: $dir"
        fi
    done

    return $failed
}

main() {
    log_info "Starting workspace setup..."

    # Handle empty or unset NEEDED_WORK_DIRS
    if [[ -z "${NEEDED_WORK_DIRS:-}" ]]; then
        log_warn "No directories specified in NEEDED_WORK_DIRS"
        return 0
    fi

    log_info "Processing directories: ${NEEDED_WORK_DIRS}"

    if ! process_directories "$NEEDED_WORK_DIRS"; then
        log_error "Some directories failed to process"
        return 1
    fi

    log_info "Workspace setup completed successfully"
}

# Execute main function with error handling
if ! main "$@"; then
    log_error "Script failed"
    exit 1
fi