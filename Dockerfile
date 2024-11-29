FROM node:22-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# ----------------------------
FROM base AS build

COPY . /usr/src/app
WORKDIR /usr/src/app

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

RUN pnpm packages build

# Извлекаем приложения в отдельные директории
RUN pnpm deploy --filter=@app/novel-next-app /novel-next-app
RUN pnpm deploy --filter=@app/docs /docs

# ----------------------------
FROM base AS docs-build

COPY --from=build /docs /docs
#COPY ./apps/docs/.env.production /docs/.env.production

WORKDIR /docs
RUN pnpm build

# Проверка содержимого директории после сборки
RUN ls -la /docs
RUN ls -la /docs/dist

# ----------------------------
FROM nginx:alpine AS docs
COPY --from=docs-build /docs/dist /usr/share/nginx/html

# Add a custom Nginx configuration
COPY ./apps/docs/nginx.conf /etc/nginx/conf.d/default.conf

# Start the server by default, this can be overwritten at runtime
EXPOSE 8080
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]

# ----------------------------
FROM base AS novel-next-app-build

COPY --from=build /novel-next-app /novel-next-app
#COPY ./apps/novel-next-app/.env.production /novel-next-app/.env.production

WORKDIR /novel-next-app
RUN pnpm build

# Проверка содержимого директории после сборки
RUN ls -la /novel-next-app
RUN ls -la /novel-next-app/dist

# ----------------------------
FROM nginx:alpine AS novel-next-app
COPY --from=novel-next-app-build /novel-next-app/dist /usr/share/nginx/html

# Add a custom Nginx configuration
COPY ./apps/web/nginx.conf /etc/nginx/conf.d/default.conf

# Start the server by default, this can be overwritten at runtime
EXPOSE 8080
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
