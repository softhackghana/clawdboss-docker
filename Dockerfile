# ============================================================
# Clawdboss Docker Image
# Hardened, multi-agent OpenClaw setup — containerized
# https://github.com/NanoFlow-io/clawdboss
# ============================================================

FROM node:22-bookworm

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    git \
    curl \
    build-essential \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Clone Clawdboss into the image
RUN git clone https://github.com/NanoFlow-io/clawdboss.git /opt/clawdboss \
    && chmod +x /opt/clawdboss/setup.sh

# Create non-root user (uid 1000 matches default host user)
RUN groupadd -g 1000 openclaw \
    && useradd -m -u 1000 -g openclaw -s /bin/bash openclaw \
    && mkdir -p /home/openclaw/.openclaw \
    && chown -R openclaw:openclaw /home/openclaw

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER openclaw
WORKDIR /home/openclaw

# Gateway port
EXPOSE 18789

ENTRYPOINT ["entrypoint.sh"]
