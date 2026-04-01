FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install -g @quasar/cli && npm ci
COPY . .
EXPOSE 8080
CMD ["quasar", "dev", "--hostname", "0.0.0.0"]
