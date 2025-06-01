# Use the Debian-based n8n image so apt-get is available
FROM n8nio/n8n:latest-debian-slim

# Switch to root to install system dependencies
USER root

# Install Python3, pip, Node.js, npm, git, and ffmpeg
RUN apt-get update && \
    apt-get install -y \
      python3 \
      python3-pip \
      nodejs \
      npm \
      git \
      ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone Kokoro TTS and install its Python dependencies
RUN git clone https://github.com/irevenko/kokoro-tts.git /opt/kokoro-tts && \
    pip3 install --no-cache-dir torch soundfile && \
    pip3 install --no-cache-dir -r /opt/kokoro-tts/requirements.txt

# Install Scriptimate globally via npm
RUN npm install -g scriptimate

# Ensure Kokoro-TTS directory is owned by the 'node' user (n8n runs as 'node')
RUN chown -R node:node /opt/kokoro-tts

# Switch back to the 'node' user for n8n runtime
USER node

# (The ENTRYPOINT and CMD for n8n are inherited from the base image)
