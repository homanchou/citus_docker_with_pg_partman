FROM postgres:11
ARG VERSION=8.2.1
LABEL maintainer="Citus Data https://citusdata.com" \
    org.label-schema.name="Citus" \
    org.label-schema.description="Scalable PostgreSQL for multi-tenant and real-time workloads" \
    org.label-schema.url="https://www.citusdata.com" \
    org.label-schema.vcs-url="https://github.com/citusdata/citus" \
    org.label-schema.vendor="Citus Data, Inc." \
    org.label-schema.version=${VERSION} \
    org.label-schema.schema-version="1.0"

ENV CITUS_VERSION ${VERSION}.citus-1

# apt-get update && apt-get install unzip && apt-get --assume-yes install
# build-essential
#&& apt-get --assume-yes install postgresql-server-dev-11 && apt-get install  -y wget \
#   && wget https://github.com/pgpartman/pg_partman/archive/v4.0.0.zip -O 4.0.0.zip \
#   && unzip 4.0.0.zip \
#   && cd /pg_partman-4.0.0 && pwd && make install && make NO_BGW=1 install

# install Citus
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-8.2=$CITUS_VERSION \
    postgresql-$PG_MAJOR-hll=2.12.citus-1 \
    postgresql-$PG_MAJOR-topn=2.2.0 \
    postgresql-$PG_MAJOR-partman \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# add citus to default PostgreSQL config
RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY 000-configure-stats.sh 001-create-citus-extension.sql /docker-entrypoint-initdb.d/

# add health check script
COPY pg_healthcheck /

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck
