# Use a minimal Node.js base image (Debian-based)
FROM node:18-slim

# Switch to root to install system dependencies
USER root

# Install system dependencies:
#  - python3, python3-pip, python3-dev, build-essential (for Kokoro TTS dependencies)
#  - git, wget (to clone/download Kokoro and its model files)
#  - ffmpeg (to merge audio/video in n8n workflows)
#  - libsndfile1-dev (required by pysoundfile)
#  - libportaudio2 & portaudio19-dev (for sounddevice → PortAudio)
#  - Chromium + Puppeteer libraries (for Scriptimate’s headless Chrome)
#  - Fonts (optional, for any HTML/SVG rendering)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python3-dev \
      build-essential \
      git \
      wget \
      ffmpeg \
      libsndfile1-dev \
      libportaudio2 \
      portaudio19-dev \
      # Puppeteer/Scriptimate dependencies:
      ca-certificates \
      fonts-liberation \
      libasound2 \
      libatk1.0-0 \
      libc6 \
      libcairo2 \
      libcups2 \
      libdbus-1-3 \
      libexpat1 \
      libfontconfig1 \
      libgcc1 \
      libgconf-2-4 \
      libgdk-pixbuf2.0-0 \
      libglib2.0-0 \
      libgtk-3-0 \
      libnspr4 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libstdc++6 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxi6 \
      libxrandr2 \
      libxrender1 \
      libxss1 \
      libxtst6 \
      lsb-release \
      xdg-utils \
      libgbm1 \
      chromium \
      fonts-roboto \
      fonts-open-sans \
    && rm -rf /var/lib/apt/lists/*

# Install n8n globally
RUN npm install -g n8n

# Install Scriptimate globally.
# Skip Puppeteer’s bundled Chromium because we already installed 'chromium' above
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g scriptimate

# -------------------------------------------------------------------
# Clone and install Kokoro TTS into /opt/kokoro-tts
# -------------------------------------------------------------------
RUN git clone https://github.com/nazdridoy/kokoro-tts.git /opt/kokoro-tts
WORKDIR /opt/kokoro-tts

# Install Python dependencies for Kokoro TTS.
# The --break-system-packages flag allows pip to override system Python packages
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Download Kokoro model and voice files (v1.0) into /opt/kokoro-tts/models
RUN mkdir -p /opt/kokoro-tts/models \
 && cd /opt/kokoro-tts/models \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx

# Add Kokoro TTS’s root folder to PATH so `kokoro-tts` is available anywhere
ENV PATH="/opt/kokoro-tts:${PATH}"

# Switch back to the non-root 'node' user (n8n expects to run as 'node')
USER node

# Set working directory and expose n8n’s default port
WORKDIR /usr/src/app
EXPOSE 5678

# By default, start n8n
CMD ["n8n", "start"]
