ARG OLS_VERSION
ARG PHP_VERSION
FROM litespeedtech/openlitespeed:${OLS_VERSION}-${PHP_VERSION}

ARG PHP_VERSION
RUN apt-get update && apt-get install -y ${PHP_VERSION}-apcu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
