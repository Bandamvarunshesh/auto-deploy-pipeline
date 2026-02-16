#!/usr/bin/env bash
set -euo pipefail

# ========== CONFIG ==========
PROJECT_NAME="auto-deploy"
CLUSTER_NAME="auto-deploy"
IMAGE_TAG="auto-deploy:local"
K8S_DIR="k8s"
KIND_CONFIG="infra/kind/kind-config.yaml"
LOCAL_PORT="8080"
HEALTH_URL="http://localhost:${LOCAL_PORT}/health"

# Set to true if you want the script to commit+push to GitHub
DO_GIT_PUSH="${DO_GIT_PUSH:-false}"

# ========== HELPERS ==========
say() { echo "▶ $*"; }
die() { echo "❌ $*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing '$1'. Install it and retry."
}

cleanup_portforward() {
  if [[ -n "${PF_PID:-}" ]] && ps -p "$PF_PID" >/dev/null 2>&1; then
    kill "$PF_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup_portforward EXIT

# ========== CHECKS ==========
need docker
need kubectl
need kind
need curl

[[ -f Dockerfile ]] || die "Run this from repo root (Dockerfile not found)."
[[ -d "$K8S_DIR" ]] || die "K8S dir not found: $K8S_DIR"

# Optional cleanup: if service.yaml exists at repo root, move it into k8s/
if [[ -f "service.yaml" && ! -f "$K8S_DIR/service.yaml" ]]; then
  say "Moving root service.yaml -> $K8S_DIR/service.yaml"
  mv service.yaml "$K8S_DIR/service.yaml"
fi

# ========== 1) BUILD IMAGE ==========
say "1) Build Docker image: $IMAGE_TAG"
docker build -t "$IMAGE_TAG" .

# ========== 2) CREATE KIND CLUSTER IF NEEDED ==========
say "2) Ensure kind cluster exists: $CLUSTER_NAME"
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  say "   Cluster already exists."
else
  if [[ -f "$KIND_CONFIG" ]]; then
    say "   Creating cluster using config: $KIND_CONFIG"
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
  else
    say "   Creating cluster without config"
    kind create cluster --name "$CLUSTER_NAME"
  fi
fi

# ========== 3) LOAD IMAGE INTO KIND ==========
say "3) Load image into kind"
kind load docker-image "$IMAGE_TAG" --name "$CLUSTER_NAME"

# ========== 4) DEPLOY TO K8S ==========
say "4) Apply Kubernetes manifests"
kubectl apply -f "$K8S_DIR/"

say "5) Wait for rollout"
kubectl rollout status "deployment/${PROJECT_NAME}" --timeout=180s

say "6) Show status"
kubectl get pods
kubectl get deploy
kubectl get svc

# ========== 7) PORT-FORWARD + HEALTH CHECK ==========
say "7) Port-forward service and health-check"
kubectl port-forward "svc/${PROJECT_NAME}-svc" "${LOCAL_PORT}:80" >/tmp/pf.log 2>&1 &
PF_PID=$!
sleep 1

say "   Curl: $HEALTH_URL"
curl -s "$HEALTH_URL" || {
  echo
  echo "Port-forward logs:"
  tail -n 50 /tmp/pf.log || true
  die "Health check failed."
}
echo
say "✅ Health check passed."

# ========== 8) OPTIONAL: GIT COMMIT + PUSH ==========
if [[ "$DO_GIT_PUSH" == "true" ]]; then
  need git
  say "8) Git add/commit/push"
  git add .
  git commit -m "Automated run update" || true
  git push
  say "✅ Pushed to GitHub."
else
  say "8) Skipping git push (set DO_GIT_PUSH=true to enable)"
fi

say "🎉 DONE. App is live at: $HEALTH_URL"
say "Stop port-forward anytime with: kill $PF_PID (or Ctrl+C if running foreground)."
