# build stage
FROM node:lts-alpine as build-stage
ARG VERSION=21.09.2

WORKDIR /app

ADD https://github.com/bastienwirtz/homer/archive/refs/tags/v${VERSION}.tar.gz /app
RUN tar xvzf v${VERSION}.tar.gz

WORKDIR /app/homer-${VERSION}

RUN yarn install --frozen-lockfile
RUN yarn build

# production stage
FROM alpine:3.11
ARG VERSION=21.09.2

ENV USER darkhttpd
ENV GROUP darkhttpd
ENV GID 911
ENV UID 911
ENV PORT 8080

RUN addgroup -S ${GROUP} -g ${GID} && adduser -D -S -u ${UID} ${USER} ${GROUP} && \
    apk add -U --no-cache su-exec darkhttpd

COPY --from=build-stage --chown=${USER}:${GROUP} /app/homer-${VERSION}/dist /www/
COPY --from=build-stage --chown=${USER}:${GROUP} /app/homer-${VERSION}/dist/assets /www/default-assets
COPY files/entrypoint.sh /entrypoint.sh
COPY files/*.png /www/

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/ || exit 1

EXPOSE ${PORT}
VOLUME /www/assets
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

LABEL "org.opencontainers.image.documentation"="https://docs.osism.tech" \
      "org.opencontainers.image.licenses"="ASL 2.0" \
      "org.opencontainers.image.source"="https://github.com/osism/container-image-homer" \
      "org.opencontainers.image.url"="https://www.osism.tech" \
      "org.opencontainers.image.vendor"="OSISM GmbH"
