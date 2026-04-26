# Deployment Architecture & Configuration

This document outlines the cloud infrastructure and operational procedures for deploying the Kora Analytics platform to AWS.

## 1. Infrastructure Setup

Our architecture uses AWS to provide secure, cost-effective compute capacity.

- **Compute Capacity**: Provisioned an Amazon Linux 2023 `t2.micro` EC2 instance, providing a lightweight, container-ready foundation.
- **Security Group (Firewall)**:
  - **HTTP (Port 80)**: Open to the world (`0.0.0.0/0`) to allow legitimate client traffic.
  - **SSH (Port 22)**: Restricted strictly to the administrator's IP address to prevent brute-force and unauthorized access attempts.
- **Identity & Access Management (IAM)**: An IAM user/role was created and provisioned with scoped credentials exclusively for the GitHub Actions pipeline, following the principle of least privilege to securely access the server and the container registry.

## 2. Server Configuration (Docker Installation)

The following commands were executed on the Amazon Linux 2023 EC2 instance to prepare the container runtime environment:

```bash
# Update the system packages to the latest secure versions
sudo dnf update -y

# Install the Docker engine
sudo dnf install docker -y

# Start the Docker daemon immediately
sudo systemctl start docker

# Ensure Docker starts automatically to survive reboots
sudo systemctl enable docker

# Allow the default ec2-user to execute docker commands without sudo
sudo usermod -aG docker ec2-user
```
*(Note: Logging out and back in is required for the group changes to take effect.)*

## 3. Deployment & Verification

Software delivery is fully automated. When new code is pushed to the `main` branch, the Continuous Delivery pipeline runs tests, builds an immutable image tagged with the Git commit SHA, and pushes it to the registry. 

Our GitHub Actions pipeline then automatically authenticates via SSH, pulls the newly tagged image, and restarts the container using Docker Compose.

**To verify the deployment is successfully resolving traffic:**
```bash
curl http://<YOUR_EC2_PUBLIC_IP>/health
```

## 4. Log Management

If anomalies occur, an engineer can investigate the live streaming telemetry directly on the host using:

```bash
docker logs -f <container_name>
```
*(Alternatively, `docker compose logs -f api` from within the root application directory)*
