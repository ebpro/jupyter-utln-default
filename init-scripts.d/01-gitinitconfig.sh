#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Configuring Git defaults...${NC}"

# Function to safely set git config
configure_git() {
    local key=$1
    local value=$2
    if ! git config --get "${key}" &>/dev/null; then
        echo -e "${GREEN}Setting ${key}=${value}${NC}"
        git config --global "${key}" "${value}"
    fi
}

# Function to setup SSH known hosts safely
setup_ssh_known_hosts() {
    local ssh_dir="${HOME}/.ssh"
    local known_hosts="${ssh_dir}/known_hosts"

    # Add GitHub's SSH key if not already present
    if ! ssh-keygen -F github.com &>/dev/null; then
        echo -e "${YELLOW}Adding GitHub's SSH key to known_hosts...${NC}"
        touch "${known_hosts}"
        ssh-keyscan -t rsa,ecdsa,ed25519 github.com 2>/dev/null >> "${known_hosts}"
        chmod 600 "${known_hosts}"
        chown "${NB_USER}:${NB_USER}" "${known_hosts}"
    fi
}

# Main execution
main() {
    # Configure Git defaults
    configure_git "init.defaultBranch" "main"
    configure_git "pull.rebase" "false"
    configure_git "fetch.prune" "true"
    configure_git "core.autocrlf" "input"
    configure_git "core.fileMode" "true"
    
    # Setup credential store based on OS
    if [[ "$(uname)" == "Darwin" ]]; then
        configure_git "credential.helper" "osxkeychain"
    else
        configure_git "credential.credentialStore" "gpg"
    fi

    # Setup SSH known hosts
    setup_ssh_known_hosts

    echo -e "${GREEN}Git configuration completed successfully${NC}"
}

# Execute main function
main "$@"