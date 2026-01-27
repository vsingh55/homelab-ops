FROM node:20-bullseye-slim

# 1. Install Python3, SSH, and System Tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    openssh-client \
    git \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Install n8n globally
RUN npm install -g n8n

# 3. Create user and directories
USER node
RUN mkdir -p /home/node/scripts
WORKDIR /home/node

# 4. Entrypoint
CMD ["n8n", "start"]