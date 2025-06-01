FROM node:18-slim

# Install system dependencies for Python, Git, FFmpeg, and Puppeteer/Chrome
RUN apt-get update && apt-get install -y python3 python3-pip git \
    libnss3-dev libatk-bridge2.0-0 libcups2 libgtk-3-0 libgbm-dev ffmpeg \
    chromium fonts-roboto fonts-open-sans \
  && rm -rf /var/lib/apt/lists/*

# Install n8n (global) 
RUN npm install -g n8n

# Install Scriptimate (global). Skip Puppeteer's bundled Chromium (we use apt's).
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g scriptimate

# Clone and install Kokoro TTS into /opt/kokoro-tts
RUN git clone https://github.com/nazdridoy/kokoro-tts.git /opt/kokoro-tts
WORKDIR /opt/kokoro-tts
RUN pip3 install -r requirements.txt

# Download Kokoro model and voice files (v1.0)
RUN mkdir -p /opt/kokoro-tts/models \
 && cd /opt/kokoro-tts/models \
 && wget https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin \
 && wget https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx

# Add Kokoro CLI to PATH
ENV PATH="/opt/kokoro-tts:${PATH}"

# Expose default n8n port
EXPOSE 5678

# (Optional) copy a start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Default command: run n8n
CMD ["/start.sh"]
