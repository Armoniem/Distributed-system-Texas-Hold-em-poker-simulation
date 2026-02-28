# ♠ PokerEval — Distributed Texas Hold'em Poker Analyzer

A production-grade distributed system for **evaluating**, **comparing**, and **calculating win probabilities** for Texas Hold'em poker hands.

| Layer | Technology |
|---|---|
| Backend | Go 1.21 + gRPC + gRPC-Gateway (HTTP/JSON) |
| Frontend | Flutter Web (Clean Architecture + Provider) |
| Deployment | Docker → Artifact Registry → GKE Autopilot |
| Load Testing | k6 |

---

## 📁 Project Structure

```
.
├── backend/          # Go gRPC service
│   ├── cmd/server/   # main.go entrypoint
│   ├── gen/          # hand-written proto stubs (pb.go + pb.gw.go)
│   └── internal/
│       ├── poker/    # card, evaluator, monte carlo
│       └── server/   # gRPC handler + tests
├── frontend/         # Flutter Web app
│   ├── lib/
│   │   ├── core/     # config, theme, providers, widgets
│   │   └── features/ # dashboard, evaluator, comparator, probability, health
│   └── web/
├── proto/            # pokereval.proto definition
├── k8s/              # Kubernetes manifests
├── tests/k6/         # Load tests
└── docker-compose.yml
```

---

## 🃏 Card Format

A card is a **2-character string**: `SUIT + RANK`

| Suit | Code | Rank | Code |
|------|------|------|------|
| Hearts | `H` | 2–9 | `2`–`9` |
| Spades | `S` | Ten | `T` |
| Diamonds | `D` | Jack | `J` |
| Clubs | `C` | Queen | `Q` |
| | | King | `K` |
| | | Ace | `A` |

**Examples:** `HA` (Ace of Hearts), `S7` (7 of Spades), `CT` (Ten of Clubs)

---

## 🚀 API Reference

All HTTP endpoints accept and return JSON via `POST`.

### Health Check

```bash
curl http://BACKEND_URL/healthz
```

### 1. Evaluate Hand

```bash
curl -X POST http://BACKEND_URL/pokereval.PokerEval/EvaluateHand \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SK"],
    "community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
  }'
```

**Response:**
```json
{
  "best_hand": ["HA", "HQ", "HJ", "HT", "HK"],
  "category": "Royal Flush",
  "strength": 9437184
}
```

### 2. Compare Hands

```bash
curl -X POST http://BACKEND_URL/pokereval.PokerEval/CompareHands \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards_1": ["HA", "SK"],
    "community_cards_1": ["HQ", "HJ", "HT", "D2", "C3"],
    "hole_cards_2": ["D9", "C8"],
    "community_cards_2": ["HQ", "HJ", "HT", "D5", "C6"]
  }'
```

**Response:**
```json
{
  "hand1": { "best_hand": [...], "category": "Royal Flush", "strength": 9437184 },
  "hand2": { "best_hand": [...], "category": "Straight", "strength": 4194496 },
  "winner": "player1"
}
```

### 3. Win Probability (Monte Carlo)

```bash
curl -X POST http://BACKEND_URL/pokereval.PokerEval/CalculateWinProbability \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": [],
    "num_players": 2,
    "num_simulations": 10000
  }'
```

**Response:**
```json
{
  "win_probability": 84.72,
  "draw_probability": 0.08,
  "simulations_run": 10000,
  "win_count": 8472,
  "draw_count": 8
}
```

---

## 🏗️ Local Development

### Backend

```bash
cd backend
go test ./...          # run unit tests
go run ./cmd/server    # start server
```

### Docker Compose

```bash
docker-compose up --build
# Backend: http://localhost:8080
# Frontend: http://localhost:3000
```

---

## ☁️ GKE Deployment

### 1. Set variables

```bash
export PROJECT_ID=your-project-id
export REGION=europe-west1
export REGISTRY=${REGION}-docker.pkg.dev/${PROJECT_ID}/pokereval
export BACKEND_URL=http://INGRESS_IP   # fill after step 6
```

### 2. Create Artifact Registry

```bash
gcloud artifacts repositories create pokereval \
  --repository-format=docker \
  --location=${REGION}
```

### 3. Build & push backend

```bash
gcloud builds submit --tag ${REGISTRY}/backend:latest \
  --config=cloudbuild-backend.yaml .
```

Or with Docker:

```bash
docker build --platform linux/amd64 -t ${REGISTRY}/backend:latest -f backend/Dockerfile .
docker push ${REGISTRY}/backend:latest
```

### 4. Build & push frontend

```bash
docker build --platform linux/amd64 \
  --build-arg BACKEND_URL=${BACKEND_URL} \
  -t ${REGISTRY}/frontend:latest \
  ./frontend
docker push ${REGISTRY}/frontend:latest
```

### 5. Create GKE cluster

```bash
gcloud container clusters create-auto pokereval-cluster \
  --location=${REGION}
gcloud container clusters get-credentials pokereval-cluster --location=${REGION}
```

### 6. Deploy

```bash
# Substitute image references
sed -i "s|REGION-docker.pkg.dev/PROJECT_ID|${REGISTRY}|g" k8s/*.yaml

kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/backend-hpa.yaml

# Wait for ingress IP (~5 min)
kubectl get ingress pokereval-ingress --watch
```

### 7. Rebuild frontend with real IP

```bash
export BACKEND_URL=http://$(kubectl get ingress pokereval-ingress -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
# Rebuild & push frontend with real URL, then rollout restart
kubectl rollout restart deployment/pokereval-frontend
```

---

## 📊 Load Testing

```bash
# Install k6: https://k6.io/docs/getting-started/installation/
k6 run tests/k6/load_test.js -e BASE_URL=http://BACKEND_URL
```

---

## 🧪 Running Tests

```bash
cd backend
go test ./... -v -race -count=1
```

---

## 📐 Architecture

```
Browser / curl
     │
     ▼
[GKE Ingress – GCE Load Balancer]
     │                    │
     ▼ /pokereval.*        ▼ /
[Backend Pod]         [Frontend Pod]
Go + gRPC             Flutter Web
Port 8080 (HTTP)      nginx:80
Port 50051 (gRPC)        │
     │                   │ (HTTP to backend)
     ▼
[Hand Evaluator]
[Monte Carlo Engine (8 goroutines)]
```

---

## 📋 Deliverables

| Item | Value |
|------|-------|
| GitHub Repository | https://github.com/Armoniem/Distributed-system-Texas-Hold-em-poker-simulation |
| Backend HTTP URL | `http://INGRESS_IP` (fill after deploy) |
| Frontend URL | `http://INGRESS_IP` (fill after deploy) |
