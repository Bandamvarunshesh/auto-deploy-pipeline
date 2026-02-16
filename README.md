# Cloud-Native Auto Deployment Pipeline

# Overview
This project implements an end-to-end automated deployment pipeline using modern DevOps practices. It demonstrates how application code can be tested, containerized, deployed to Kubernetes, and validated using health checks with support for safe rollback.
The goal of this project is to simulate a production-grade CI/CD workflow in a local Kubernetes environment.

# Overview
This project implements an end-to-end automated deployment pipeline using modern DevOps practices. It demonstrates how application code can be tested, containerized, deployed to Kubernetes, and validated using health checks with support for safe rollback.
The goal of this project is to simulate a production-grade CI/CD workflow in a local Kubernetes environment.

# Objectives
Implement Continuous Integration using GitHub Actions
Containerize an application using Docker
Deploy workloads to Kubernetes
Configure rolling updates with readiness and liveness probes
Enable safe rollback for failed deployments
Apply Infrastructure as Code principles

# Architecture Flow
Developer pushes code to GitHub
CI pipeline runs automated tests
Docker image is built
Image is deployed to Kubernetes
Rolling update strategy is applied
Health checks validate deployment
Rollback is available if deployment fails

# Technology Stack
Python (Flask)
Docker
Kubernetes (Kind for local cluster)
GitHub Actions
Terraform
Bash scripting

# Project Structure
auto-deploy-pipeline/
├── app.py
├── Dockerfile
├── requirements.txt
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── infra/
├── tests/
├── run_all.sh
└── README.md

Running the Project Locally
1. Build Docker Image
docker build -t auto-deploy:local .

2. Create Kind Cluster
kind create cluster --name auto-deploy

3. Load Image into Cluster
kind load docker-image auto-deploy:local --name auto-deploy

4. Deploy to Kubernetes
kubectl apply -f k8s/

5. Verify Deployment
kubectl get pods
kubectl get deploy
kubectl get svc

6. Access Application
kubectl port-forward svc/auto-deploy-svc 8080:80

Open in browser: http://localhost:8080/health

Expected response: {"status":"ok","version":"k8s"}

Rollback Strategy: 
kubectl rollout history deployment/auto-deploy

Rollback to previous revision: 
kubectl rollout undo deployment/auto-deploy

CI/CD Pipeline
The GitHub Actions workflow performs:
Dependency installation
Automated test execution
Docker image build
Deployment steps
This ensures only validated builds are deployed.

Future Enhancements
Blue/Green deployment strategy
Canary deployments
Helm chart packaging
Monitoring integration
GitOps-based deployment

Conclusion
This project demonstrates practical implementation of containerization, orchestration, CI/CD automation, and deployment reliability using a cloud-native approach.
