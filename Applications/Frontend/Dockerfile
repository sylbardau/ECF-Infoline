FROM node:22-alpine AS build

WORKDIR /Frontend
COPY package*.json ./
# Téléchargement des dépendances en cache séparé
RUN npm ci

COPY . .
RUN npm run build 

# Image de runtime
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /Frontend/dist/Frontend /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
