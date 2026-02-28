# ─── Stage 1: Go build ─────────────────────────────────────────────────────────
# Hand-written proto stubs in backend/gen/ are committed to the repo,
# removing the need for protoc or network access during the image build.
FROM --platform=linux/amd64 golang:1.21-alpine AS builder

WORKDIR /app

# Download dependencies (cached as separate layer)
COPY backend/go.mod backend/go.sum* ./
RUN go mod download

# Copy full source including gen/ stubs
COPY backend/ .

# Build for linux/amd64 (GKE node architecture)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/server ./cmd/server

# ─── Stage 2: Minimal runtime image ──────────────────────────────────────────
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /bin/server /server

# gRPC
EXPOSE 50051
# HTTP gateway
EXPOSE 8080

USER nonroot:nonroot
ENTRYPOINT ["/server"]
