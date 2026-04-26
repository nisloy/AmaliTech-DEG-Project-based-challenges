# DeployReady: Kora Analytics DevOps Solution

Welcome to the automated deployment and containerization solution for the Kora Analytics API. This repository demonstrates best practices in Docker containerization, security, and CI/CD automation.

##  Architecture Overview

This project implements a robust, lightweight, and secure pipeline using the following stack:

- **Application:** Node.js Express API
- **Containerization:** Docker & Docker Compose
- **CI/CD Pipeline:** GitHub Actions
- **Cloud Infrastructure:** AWS EC2 (`t3.micro` running Amazon Linux 2023)
- **Container Registry:** GitHub Container Registry (GHCR)

By utilizing a **"Pull-based" deployment model** with a GitHub Actions Self-Hosted Runner natively on the EC2 instance, we have completely eliminated the need for inbound SSH rules from GitHub's IP pool, establishing a highly secure network perimeter.

## Setup Steps

### Local Development

1. Clone the repository and navigate to the root directory:
   ```bash
   git clone <your-repo-url>
   cd DeployReady
   ```

2. Create your environment variables file from the provided template:
   ```bash
   cp .env.example .env
   ```

3. Start the application locally using Docker Compose:
   ```bash
   docker compose up --build
   ```

4. Verify the API is running at the health endpoint:
   ```bash
   curl http://localhost:3000/health
   ```

### Production Deployment

All deployments to the production EC2 server are fully automated.

1. Ensure the GitHub Actions Self-Hosted Runner is configured as a background service on your EC2 instance.
2. Push your confirmed code changes to the `main` branch.
3. The pipeline handles the rest sequentially:
   - Validates the code via `npm test`.
   - Builds a fresh Docker image and tags it securely with the exact Git commit SHA.
   - Pushes the image artifact to GHCR.
   - Informs the EC2 server to pull the artifact and natively orchestrate the deployment.
   - Verifies the live production `/health` endpoint and automatically rolls back if the application fails to boot.

For granular details on the AWS Virtual Machine configuration and manual Docker verification steps, please see our [DEPLOYMENT.md](./DEPLOYMENT.md).

##  Decisions Made

- **Alpine Linux Container Base:** Chosen to drastically reduce image size, speed up pipeline transmission times, and minimize the container's security attack surface.
- **Dependency Caching:** The `Dockerfile` copies `package.json` separate from source code to leverage Docker layer caching, significantly speeding up consecutive CI builds.
- **Non-Root Execution:** The Dockerfile rigorously enforces `USER node` so the application runs with least-privilege, heavily mitigating Docker escape vulnerabilities.
- **Self-Hosted Runner Integration:** Selected over traditional SSH pipelines to allow the server to securely *pull* changes via outbound HTTPS. This permitted us to lock down Port 22 exclusively to the administrator IP address.
- **Automated Pipeline Rollbacks:** Ensures production resilience. We capture the running container's state prior to deployment. If the new deployment fails its post-flight `curl` health check, the system instantly self-heals by reverting to the previous working state.
