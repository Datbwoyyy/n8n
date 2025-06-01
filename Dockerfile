# Use the official n8n image as the base
FROM n8nio/n8n:latest

# Switch to root user to install system dependencies
USER root

# Install Python3, pip, Node.js, npm, git, and ffmpeg
RUN apt-get update && \
    apt-get install -y python3 python3-pip nodejs npm git ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone Kokoro TTS and install its Python dependencies
RUN git clone https://github.com/irevenko/kokoro-tts.git /opt/kokoro-tts
RUN pip3 install --no-cache-dir torch soundfile && \
    pip3 install --no-cache-dir -r /opt/kokoro-tts/requirements.txt

# Install Scriptimate globally via npm
RUN npm install -g scriptimate

# Ensure /usr/src/n8n has the proper ownership (n8n runs as 'node' user)
RUN chown -R node:node /opt/kokoro-tts

# Switch back to the 'node' user for n8n runtime
USER node

# Set the working directory (where n8n stores data, workflows, etc.)
WORKDIR /usr/src/n8n

# Expose n8n’s default port
EXPOSE 5678

# Entrypoint is inherited from the n8n base image
# (This ensures n8n starts as usual when the container runs)

# If you need any environment variables for Kokoro or n8n, you can add them here:
# ENV KOKORO_MODEL_PATH=/opt/kokoro-tts/models
# ENV N8N_BASIC_AUTH_ACTIVE=true
# ENV N8N_BASIC_AUTH_USER=Victor
# ENV N8N_BASIC_AUTH_PASSWORD=123Kelly123
