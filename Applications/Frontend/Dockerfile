FROM node:22-alpine AS build

WORKDIR /Frontend
COPY package*.json ./
# Téléchargement des dépendances en cache séparé
RUN npm ci

COPY . .
RUN npm run build 
RUN ls -la /Frontend/dist && ls -la /Frontend/dist/*
# Image de runtime
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /Frontend/dist/Frontend/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
