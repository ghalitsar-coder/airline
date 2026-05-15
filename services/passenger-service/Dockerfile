FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/main.go

FROM alpine:3.19

RUN apk --no-cache add ca-certificates curl

WORKDIR /app

COPY --from=builder /app/server ./server

EXPOSE 8001

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8001/health || exit 1

CMD ["./server"]
