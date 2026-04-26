FROM node:18-alpine

WORKDIR /usr/src/app
COPY app/package*.json ./
RUN npm install
COPY app/ ./

ENV PORT=3000
EXPOSE $PORT
# Drop root privileges for security
USER node
CMD ["npm", "start"]
