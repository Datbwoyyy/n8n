# Base image
FROM node:18-slim

# Set working directory
WORKDIR /app

# Install n8n globally
RUN npm install -g n8n

# Make folders accessible
RUN mkdir -p /home/node/.n8n /files && \
    chown -R node:node /home/node /app /files

# Set environment variables
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin
ENV N8N_BASIC_AUTH_PASSWORD=admin123
ENV N8N_PORT=5678
ENV WEBHOOK_TUNNEL_URL=https://your-subdomain.onrender.com

# Set user
USER node

# Expose port
EXPOSE 5678

# Start n8n
CMD ["n8n"]
