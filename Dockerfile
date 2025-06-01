# Use a minimal Node.js base image (Debian-based)
FROM node:18-slim

# Install system dependencies: Python3, pip, Git, FFmpeg, and libraries needed by Puppeteer/Chrome
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip \
      git \
      libnss3-dev libatk-bridge2.0-0 libcups2 libgtk-3-0 libgbm-dev \
      ffmpeg \
      chromium \
      fonts-roboto fonts-open-sans \
    && rm -rf /var/lib/apt/lists/*

# Install n8n globally
RUN npm install -g n8n

# Install Scriptimate globally.
# We skip Puppeteer's bundled Chromium because we already have `chromium` from apt.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g scriptimate

# -------------------------------------------------------------------
# Clone and install Kokoro TTS into /opt/kokoro-tts
# -------------------------------------------------------------------
RUN git clone https://github.com/nazdridoy/kokoro-tts.git /opt/kokoro-tts

WORKDIR /opt/kokoro-tts

# Install Python dependencies for Kokoro.
# We explicitly pass --break-system-packages to allow installing over system Python
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Download Kokoro model and voice files (v1.0) into /opt/kokoro-tts/models
RUN mkdir -p /opt/kokoro-tts/models \
 && cd /opt/kokoro-tts/models \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx

# Put Kokoro's root folder on PATH so `kokoro-tts` can be invoked directly
ENV PATH="/opt/kokoro-tts:${PATH}"

# Switch back to the non-root 'node' user for security (n8n runs as 'node')
USER node

# Ensure n8n will listen on port 5678
WORKDIR /usr/src/app
EXPOSE 5678

# By default, just run n8n
CMD ["n8n", "start"]
