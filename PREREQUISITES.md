# Prerequisites

Before setting up the microservices observability demo, ensure you have the following tools installed:

## Required Tools

### 1. Docker
- Required for Kubernetes and container operations
- Download: https://www.docker.com/products/docker-desktop
- Verify installation: `docker --version`

### 2. Kubectl
- Kubernetes command-line tool
- Installation: https://kubernetes.io/docs/tasks/tools/
- Verify installation: `kubectl version --client`

### 3. Kind (Kubernetes in Docker)
- Runs Kubernetes clusters in Docker containers
- Installation: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
- Verify installation: `kind --version`

Alternative: Use Minikube instead of Kind
- Installation: https://minikube.sigs.k8s.io/docs/start/
- Verify installation: `minikube version`

### 4. Helm
- Kubernetes package manager (for Signoz deployment)
- Installation: https://helm.sh/docs/intro/install/
- Verify installation: `helm version`

## System Requirements

- **RAM:** Minimum 8GB (16GB recommended)
- **CPU:** 4 cores recommended
- **Disk Space:** 20GB free space
- **OS:** macOS, Linux, or Windows with WSL2
- **Architecture:** Works on both x86_64/amd64 and ARM64/aarch64

### ARM64 Note

If you're on ARM64 (Apple Silicon, Raspberry Pi, etc.), use the ARM64-specific deployment script:
```bash
./scripts/deploy-arm64-microservices.sh
```

Check your architecture:
```bash
uname -m  # Shows: aarch64 (ARM64) or x86_64 (Intel/AMD)
```

## Quick Verification

Run this command to verify all prerequisites:

```bash
echo "Docker: $(docker --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "Kubectl: $(kubectl version --client --short 2>/dev/null || echo 'NOT INSTALLED')"
echo "Kind: $(kind --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "Helm: $(helm version --short 2>/dev/null || echo 'NOT INSTALLED')"
```

Once all tools are installed, proceed to the setup instructions in README.md.
