FROM golang:1.20-alpine AS builder

WORKDIR /app

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -o money_flow_calculation

# Use a smaller image for the final build
FROM alpine:latest

# Install SQLite and CA certificates
RUN apk --no-cache add ca-certificates sqlite

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/money_flow_calculation .

# Expose the application port
EXPOSE 8083

# Run the application
CMD ["./money_flow_calculation"] 