FROM daedalusproject/base_develop:202003281621

ARG CORE_VERSION

MAINTAINER Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

RUN apt-get update -qq \
    && apt-get install -qq -o=Dpkg::Use-Pty=0 -y --no-install-recommends \
    libdaedalus-core-perl=$CORE_VERSION \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

USER daedalus
