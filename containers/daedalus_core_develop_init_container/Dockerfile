FROM daedalusproject/base_develop:201905161823

ARG CORE_VERSION

MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

RUN apt-get update -qq \
    && apt-get install -qq -o=Dpkg::Use-Pty=0 -y --no-install-recommends \
    libdaedalus-core-perl=$CORE_VERSION \
    percona-server-client=8.0.15-5-1.bionic \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

USER daedalus
