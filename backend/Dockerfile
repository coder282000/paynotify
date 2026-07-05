FROM node:18-alpine

WORKDIR /app

# Copy backend package files and install dependencies
COPY backend/package*.json ./
RUN npm ci --only=production

# Copy backend source code
COPY backend/ ./

# ✅ Copy Flutter web build into container at /app/flutter_web
COPY frontend/build/web/ ./flutter_web/

# Expose port
EXPOSE 3000

# Start server
CMD ["node", "server.js"]