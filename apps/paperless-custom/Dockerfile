# Stage 1: The Builder (Compiles dependencies)
FROM python:3.11-alpine as builder

WORKDIR /usr/src/paperless

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    linux-headers

RUN git clone --branch v2.5.0 --depth 1 https://github.com/paperless-ngx/paperless-ngx.git .

# Install Python dependencies
RUN pip install --upgrade pipenv

# Stage 2: The Final Runtime (Minimal & Secure)
FROM python:3.11-alpine

# Metadata for image management
LABEL org.opencontainers.image.source="https://github.com/vsingh55/homelab-ops"
LABEL org.opencontainers.image.description="Hardened Paperless-ngx Base for Homelab (Alpine)"

# Create a non-root user 
RUN addgroup -S paperless && adduser -S paperless -G paperless

WORKDIR /usr/src/paperless

# Install ONLY runtime dependencies
RUN apk add --no-cache \
    postgresql-libs \
    imagemagick \
    ghostscript \
    tzdata

# Copy only the necessary artifacts from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Set ownership to non-root user
USER paperless

# Verify basic sanity
RUN python3 --version

CMD ["python3"]