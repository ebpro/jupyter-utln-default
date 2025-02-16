# Development Container Features

## 🛠 Core Development Tools

- **Shell**: ZSH with Prezto and Powerlevel10k theme
- **Code Editor**: VS Code Server with extensions support (as a devcontainer)
- **Version Control**: Git with gitstatus for fast status checks
- **Package Management**: apt (system), pip (Python), mamba (conda)

## 📊 Data Science & Documentation

- **Quarto**: Version 1.6.40 with Chromium support
- **TinyTeX**: 2024.11 distribution for LaTeX support
- **Pandoc**: Universal document converter
- **Python Environment**: 
  - Miniforge3 with mamba
  - Custom `jupyter-env` environment
  - Jupyter kernels for Python, Bash, and ZSH

## 🐋 Container & Orchestration

- **Docker**: Latest version with:
  - buildx for multi-platform builds
  - compose for multi-container applications
- **Kubernetes Tools**:
  - kubectl (v1.29.1)
  - Helm (v3.14.0)
  - k9s (v0.31.6)
  - kustomize (v5.3.0)
  - Minikube with Docker driver

## 🔧 Development Environment

```bash
# Directory Structure
${HOME}/
├── .TinyTeX/          # LaTeX distribution
├── .minikube/         # Minikube configuration
├── .zprezto/          # ZSH framework
├── bin/              # User binaries
├── miniforge3/       # Python environment
└── work/             # Persistent workspace
    ├── materials/    # Course materials
    └── local/        # Local workspace
```

## 🚀 Key Features

1. **Multi-architecture Support**:
   - Supports both `amd64` and `arm64`
   - Automatic platform detection

2. **Security**:
   - Non-root user `jovyan`
   - Sudo access for development tasks
   - Secure default configurations

3. **Performance**:
   - Cache mounting for package installations
   - Optimized base image
   - Minimal layer design

4. **Configuration**:
   - Persistent workspace in `/home/jovyan/work`
   - Automated startup scripts
   - Environment-specific configurations

To use all these tools in VS Code:

```bash
# Clone and open in VS Code
git clone https://github.com/ebpro/notebook-qs-base.git
code notebook-qs-base

# VS Code will prompt to "Reopen in Container"
# This will build and start the dev container
```