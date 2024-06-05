# syntax=docker/dockerfile:1-labs
FROM public.ecr.aws/docker/library/alpine:3.19 AS base
ENV TZ=UTC
WORKDIR /src

# source backend stage =========================================================
FROM base AS source

# get and extract source from git
ARG VERSION
ADD https://git.zx2c4.com/wireguard-tools.git#${BRANCH:-v$VERSION} ./

# apply available patches
RUN apk add --no-cache patch
COPY patches ./
RUN find ./ -name "*.patch" -print0 | sort -z | xargs -t -0 -n1 patch -p1 -i

# build stage ==================================================================
FROM base AS build-app

# build dependencies
RUN apk add --no-cache build-base libmnl-dev

# copy source
COPY --from=source /src/src ./

# build
ENV DESTDIR=/build/rootfs
RUN make && \
    make install \
        WITH_SYSTEMDUNITS=no \
        WITH_WGQUICK=yes \
        WITH_BASHCOMPLETION=yes

# runtime stage ================================================================
FROM base

ENV S6_VERBOSITY=0 S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV ENV="/root/.profile" WG_FILE=wg0.conf
WORKDIR /config
VOLUME /config
EXPOSE 51820/udp

# copy files
COPY --from=build-app /build/rootfs/. /
COPY ./rootfs/. /

# runtime dependencies
RUN apk add --no-cache bash openresolv iproute2 iptables \
    tzdata s6-overlay curl && \
    echo "wireguard" >> /etc/modules

# run using s6-overlay
ENTRYPOINT ["/init"]
