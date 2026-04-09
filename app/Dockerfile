FROM node:18-alpine

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --production

COPY ./src ./src

RUN mkdir -p /etc/todos

EXPOSE 3000

CMD ["node", "src/index.js"]