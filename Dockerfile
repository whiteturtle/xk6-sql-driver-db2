# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache \
    git \
    gcc \
    musl-dev \
    curl \
    tar \
    gzip

# Install xk6
RUN go install go.k6.io/xk6/cmd/xk6@latest

# Download and install IBM DB2 CLI driver
RUN mkdir -p /build/clidriver && \
    curl -L https://raw.githubusercontent.com/ibmdb/go_ibm_db/master/installer/setup.go -o setup.go && \
    go run setup.go || true

# Set environment variables for DB2 CLI driver
ENV IBM_DB_HOME=/build/clidriver
ENV CGO_CFLAGS="-I/build/clidriver/include"
ENV CGO_LDFLAGS="-L/build/clidriver/lib"
ENV CGO_ENABLED=1

# Copy source code
COPY . /build/src

# Build k6 with extensions
WORKDIR /build/src
ARG K6_VERSION=latest
RUN xk6 build \
    --with github.com/grafana/xk6-sql@latest \
    --with github.com/oleiade/xk6-encoding@latest \
    --with github.com/whiteturtle/xk6-sql-driver-db2=. \
    --output /build/k6

# Production stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    libgcc \
    libstdc++

# Copy k6 binary
COPY --from=builder /build/k6 /usr/bin/k6

# Copy DB2 CLI driver libraries
COPY --from=builder /build/clidriver/lib /usr/local/lib/db2
COPY --from=builder /build/clidriver/license /usr/local/share/db2/license

# Set runtime environment variables for DB2
ENV LD_LIBRARY_PATH=/usr/local/lib/db2:${LD_LIBRARY_PATH}
ENV IBM_DB_HOME=/usr/local/lib/db2

# Optional: Create non-root user
# RUN adduser -D -u 12345 -g 12345 k6
# USER 12345

WORKDIR /scripts

ENTRYPOINT ["k6"]
