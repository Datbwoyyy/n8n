# ─────────────────────────────────────────────────────────────────────────────
# Stage 1) Build kokoro‐tts and scriptimate dependencies behind the scenes
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.11‐slim AS kokoro‐builder

# Install minimal build tools & dependencies for kokoro‐tts
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      build-essential \
      python3-dev \
      libsndfile1-dev \
      libportaudio2 \
      portaudio19-dev \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Clone kokoro‐tts & install its Python requirements
RUN git clone https://github.com/nazdridoy/kokoro-tts.git /kokoro-tts
WORKDIR /kokoro-tts
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt

# Download kokoro model files
RUN mkdir -p /kokoro-tts/models \
 && cd /kokoro-tts/models \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx

# Stage 2) Build a minimal Node.js + n8n + kokoro + scriptimate image
# ─────────────────────────────────────────────────────────────────────────────
FROM node:18-bullseye-slim

USER root

# 1) Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      git \
      ffmpeg \
      libsndfile1 \
      libportaudio2 \
      libnss3 \
      libatk-bridge2.0-0 \
      libcups2 \
      libgtk-3-0 \
      libgbm1 \
      chromium \
      fonts-roboto \
      fonts-open-sans \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2) Install n8n
RUN npm install -g n8n@^0.290.0

# 3) Install scriptimate CLI, skipping its bundled Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g scriptimate@^1.2.30

# 4) Copy kokoro‐tts artifacts from builder stage
COPY --from=kokoro‐builder /kokoro-tts /opt/kokoro-tts

# 5) Add kokoro‐tts to PATH
ENV PATH="/opt/kokoro-tts:${PATH}"

# 6) Create a small folder for n8n’s data (Postgres/SQLite path is elsewhere)
USER node
WORKDIR /home/node

# 7) Expose n8n’s port and default command
EXPOSE 5678
CMD ["n8n", "start"]
