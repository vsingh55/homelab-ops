# Stage 1: The Builder (Compiles dependencies)
FROM python:3.11-slim-bookworm as builder

WORKDIR /usr/src/paperless

# Install build dependencies (gcc, libpq, etc.)
# We do this in a separate stage so they don't bloat the final image
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch v2.5.0 --depth 1 https://github.com/paperless-ngx/paperless-ngx.git .

# Install Python dependencies
RUN pip install --upgrade pipenv

# Stage 2: The Final Runtime (Minimal & Secure)
FROM python:3.11-slim-bookworm

# Add metadata for image management
LABEL org.opencontainers.image.source="https://github.com/vsingh55/homelab-ops"
LABEL org.opencontainers.image.description="Hardened Paperless-ngx Base for Homelab"

# Create a non-root user (Security Best Practice)
RUN addgroup --system paperless && adduser --system --group paperless

WORKDIR /usr/src/paperless

# Install ONLY runtime dependencies (no gcc/git)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    imagemagick \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Copy only the necessary artifacts from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Set ownership to non-root user
USER paperless

# Verify basic sanity
RUN python3 --version

CMD ["python3"]