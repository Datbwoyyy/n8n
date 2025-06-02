####################################
# Stage 1: Builder (has compilers)
####################################
FROM node:18-alpine AS builder

RUN apk add --no-cache \
      python3 \
      py3-pip \
      python3-dev \
      build-base \
      git \
      wget

# Clone Kokoro and build only its Python deps
RUN git clone https://github.com/nazdridoy/kokoro-tts.git /opt/kokoro-tts
WORKDIR /opt/kokoro-tts
RUN pip3 install --no-cache-dir -r requirements.txt

####################################
# Stage 2: Final (runtime only)
####################################
FROM node:18-alpine

# Copy only the built Kokoro deps from builder
COPY --from=builder /usr/lib/python3.*/site-packages /usr/lib/python3.*/site-packages
COPY --from=builder /opt/kokoro-tts /opt/kokoro-tts

# Install runtime packages (no compilers)
RUN apk add --no-cache \
      python3 \
      git \
      wget \
      ffmpeg \
      libsndfile \
      chromium \
      ttf-roboto \
      ttf-opensans

# Install n8n & Scriptimate
RUN npm install -g n8n
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g scriptimate

# Download Kokoro models
RUN mkdir -p /opt/kokoro-tts/models \
 && cd /opt/kokoro-tts/models \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin \
 && wget -q https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx

ENV PATH="/opt/kokoro-tts:${PATH}"

USER node
WORKDIR /usr/src/app
EXPOSE 5678
CMD ["n8n", "start"]
