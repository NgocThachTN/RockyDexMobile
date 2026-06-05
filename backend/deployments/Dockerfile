# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for fetch dependencies
RUN apk add --no-cache git

# Copy files
COPY go.mod ./
RUN go mod download

COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go

# Production stage
FROM alpine:latest

WORKDIR /app

# Copy binary and config
COPY --from=builder /app/main .
COPY --from=builder /app/configs/config.env ./configs/config.env

EXPOSE 8080

CMD ["./main"]
