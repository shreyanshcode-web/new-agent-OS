# WorkOS AI Deployment Guide

## Prerequisites

- Kubernetes 1.24+ (or Docker 20.10+)
- kubectl configured
- Docker registry access
- PostgreSQL 15+ (if self-managed)

## Local Development

### Using Docker Compose

```bash
# Start full stack
docker-compose up -d

# Check service health
docker-compose ps

# View logs
docker-compose logs -f

# Stop stack
docker-compose down
```

**Services:**
- Orchestrator: http://localhost:50051 (gRPC)
- Executive Agent: http://localhost:50052 (gRPC)
- PostgreSQL: localhost:5432
- RabbitMQ: localhost:5672 (Management: http://localhost:15672)
- pgAdmin: http://localhost:5050
- Redis: localhost:6379
- MinIO: http://localhost:9000 (Console: http://localhost:9001)

## Kubernetes Deployment

### 1. Build Docker Images

```bash
# Build all images locally (for development)
docker-compose build

# Or push to registry for production
docker build -t myregistry/workos/orchestrator:v1 \
  -f deploy/docker/Dockerfile.orchestrator .
docker push myregistry/workos/orchestrator:v1
```

### 2. Update Image References

Edit `deploy/k8s/workos-core.yaml` and `deploy/k8s/workos-agents.yaml`:
```yaml
image: myregistry/workos/orchestrator:v1
imagePullPolicy: IfNotPresent  # Change to Always for registry
```

### 3. Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace workos-ai

# Label namespace for network policies
kubectl label namespace workos-ai name=workos-ai

# Deploy core services (PostgreSQL, RabbitMQ, Orchestrator, Executive)
kubectl apply -f deploy/k8s/workos-core.yaml

# Deploy specialized agents
kubectl apply -f deploy/k8s/workos-agents.yaml

# Verify deployment
kubectl get pods -n workos-ai
kubectl get svc -n workos-ai
```

### 4. Verify Deployment

```bash
# Check pod status
kubectl get pods -n workos-ai -w

# View logs
kubectl logs -n workos-ai deployment/orchestrator -f

# Port forward for testing
kubectl port-forward -n workos-ai svc/orchestrator 50051:50051

# Test gRPC service
grpcurl -plaintext localhost:50051 list
```

## Scaling

### Manual Scaling

```bash
# Scale orchestrator to 5 replicas
kubectl scale deployment/orchestrator \
  --replicas=5 \
  -n workos-ai

# Scale all agents
kubectl scale deployment/hr-agent --replicas=2 -n workos-ai
kubectl scale deployment/sales-agent --replicas=2 -n workos-ai
kubectl scale deployment/dev-agent --replicas=2 -n workos-ai
kubectl scale deployment/marketing-agent --replicas=2 -n workos-ai
```

### Autoscaling

HPA (Horizontal Pod Autoscaler) is configured in `workos-core.yaml`:
- Scales orchestrator from 2 to 10 replicas
- Based on CPU (70%) and Memory (80%) utilization

Monitor HPA status:
```bash
kubectl get hpa -n workos-ai -w
kubectl describe hpa orchestrator-hpa -n workos-ai
```

## Persistent Storage

### PostgreSQL Backup

```bash
# Create backup
kubectl exec -n workos-ai postgres-pod -- \
  pg_dump -U workos workos_ai > backup.sql

# Restore from backup
kubectl exec -i -n workos-ai postgres-pod -- \
  psql -U workos workos_ai < backup.sql
```

### Volume Management

```bash
# Check PVC status
kubectl get pvc -n workos-ai

# Expand volume
kubectl patch pvc postgres-pvc -n workos-ai \
  -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

## Configuration Management

### Using ConfigMaps

Edit environment variables in `workos-core.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: workos-config
data:
  ENVIRONMENT: production
  LOG_LEVEL: info
```

Update:
```bash
kubectl apply -f deploy/k8s/workos-core.yaml
kubectl rollout restart deployment/orchestrator -n workos-ai
```

### Using Secrets

Store sensitive data:
```bash
# Create secret from file
kubectl create secret generic workos-secrets \
  --from-literal=DB_PASSWORD=... \
  --from-literal=OPENAI_API_KEY=... \
  -n workos-ai

# Or from env file
kubectl create secret generic workos-secrets \
  --from-env-file=.env \
  -n workos-ai
```

## Monitoring & Logging

### View Logs

```bash
# All pods
kubectl logs -n workos-ai -l app=orchestrator --all-containers=true

# Specific pod
kubectl logs -n workos-ai orchestrator-xyz-abc -f

# Previous container logs (if crashed)
kubectl logs -n workos-ai orchestrator-xyz-abc --previous
```

### Metrics

Access metrics from your Kubernetes cluster:
```bash
# If Prometheus is installed
kubectl port-forward -n monitoring prometheus-0 9090:9090
# Visit http://localhost:9090
```

### Events

```bash
# View cluster events
kubectl get events -n workos-ai --sort-by='.lastTimestamp'

# Describe pod for issues
kubectl describe pod orchestrator-xyz-abc -n workos-ai
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n workos-ai
kubectl describe pod <pod-name> -n workos-ai

# Check logs
kubectl logs -n workos-ai <pod-name>

# If database is issue
kubectl logs -n workos-ai postgres-0
```

### Database Connection Issues

```bash
# Test database connectivity
kubectl exec -it -n workos-ai postgres-0 -- \
  psql -U workos -d workos_ai -c "SELECT 1"

# Check service DNS
kubectl exec -it -n workos-ai orchestrator-xyz -- \
  nslookup postgres.workos-ai.svc.cluster.local
```

### Memory/CPU Issues

```bash
# Check resource usage
kubectl top pods -n workos-ai

# Check limits
kubectl describe pod <pod-name> -n workos-ai | grep -A 5 "Limits\|Requests"

# Increase limits in yaml and redeploy
kubectl set resources deployment orchestrator \
  --limits=cpu=1000m,memory=1Gi \
  -n workos-ai
```

## Upgrading

### Rolling Update

```bash
# Update image
kubectl set image deployment/orchestrator \
  orchestrator=myregistry/workos/orchestrator:v2 \
  -n workos-ai

# Monitor rollout
kubectl rollout status deployment/orchestrator -n workos-ai

# Rollback if needed
kubectl rollout undo deployment/orchestrator -n workos-ai
```

### Database Migration

```bash
# Run migration job
kubectl apply -f deploy/k8s/migration-job.yaml

# Monitor job
kubectl logs -n workos-ai job/db-migration
```

## Production Checklist

- [ ] Use specific image tags (not `latest`)
- [ ] Set resource requests and limits
- [ ] Configure liveness and readiness probes
- [ ] Enable HPA for production workloads
- [ ] Configure persistent volumes
- [ ] Set up monitoring and alerting
- [ ] Configure network policies
- [ ] Use Kubernetes Secrets for sensitive data
- [ ] Enable RBAC
- [ ] Set up backup and disaster recovery
- [ ] Configure ingress for external access
- [ ] Enable pod disruption budgets
- [ ] Set up log aggregation
- [ ] Configure rate limiting
- [ ] Enable security scanning

## Advanced Topics

### Istio Integration

```bash
# Label namespace for Istio injection
kubectl label namespace workos-ai istio-injection=enabled

# Apply Istio manifests
kubectl apply -f deploy/k8s/istio-config.yaml
```

### Multi-Region Deployment

- Deploy to multiple K8s clusters
- Use service mesh for communication
- Implement data replication

### Disaster Recovery

- Regular database backups
- PVC snapshots
- Multi-zone deployment
- Automated failover

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Deployment Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
