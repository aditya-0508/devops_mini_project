FROM node:18-alpine

ENV NODE_ENV=production

WORKDIR /usr/src/app

# Copy only package files first
COPY app/package*.json ./

RUN npm ci --omit=dev

# Copy full app code
COPY app/ .

# Use non-root user
USER node

EXPOSE 5000

CMD ["npm", "start"]
