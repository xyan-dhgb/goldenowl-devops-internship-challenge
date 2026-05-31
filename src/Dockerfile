# Use node:18-alpine as the base image for the application to ensure a lightweight and efficient environment for running the Node.js application.
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
