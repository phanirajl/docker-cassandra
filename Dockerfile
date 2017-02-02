FROM alpine:3.5

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="smizy/cassandra" \
    org.label-schema.url="https://github.com/smizy" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/smizy/docker-cassandra"

ENV CASSANDRA_VERSION    $VERSION
ENV CASSANDRA_HOME       /usr/local/apache-cassandra-${CASSANDRA_VERSION}
ENV CASSANDRA_CONF       ${CASSANDRA_HOME}/conf
ENV CASSANDRA_DATA       ${CASSANDRA_HOME}/data
ENV CASSANDRA_LOGS       ${CASSANDRA_HOME}/logs

## default
ENV CASSANDRA_CLUSTER_NAME            'Test Cluster'
ENV CASSANDRA_DATA_FILE_DIRECTORIES   ["${CASSANDRA_DATA}/data"]
ENV CASSANDRA_COMMITLOG_DIRECTORY     ${CASSANDRA_DATA}/commitlog
ENV CASSANDRA_SAVED_CACHES_DIRECTORY  ${CASSANDRA_DATA}/saved_caches
ENV CASSANDRA_HINTS_DIRECTORY         ${CASSANDRA_DATA}/hints

# Segmentation fault
# Problematic frame:
# C  [libjemalloc.so.2+0x3863]  _init+0x59b
#ENV CASSANDRA_LIBJEMALLOC             /usr/lib/libjemalloc.so.2

ENV JAVA_HOME  /usr/lib/jvm/default-jvm
ENV PATH       $PATH:${JAVA_HOME}/bin:${CASSANDRA_HOME}/bin

RUN set -x \
    && apk update \
    && apk --no-cache add \
        bash \
        jemalloc \
        openjdk8-jre \
        python \
        su-exec \
    && mirror_url=$( \
        wget -q -O - http://www.apache.org/dyn/closer.cgi/cassandra/ \
        | sed -n 's#.*href="\(http://ftp.[^"]*\)".*#\1#p' \
        | head -n 1 \
    ) \    
    && wget -q -O - ${mirror_url}/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz \
        | tar -xzf - -C /usr/local \
    ## use ${CASSANDRA_LOGS} directory for gc.log
    && sed -iE 's#-Xloggc:[^/]*/logs#-Xloggc:${CASSANDRA_LOGS}#g' ${CASSANDRA_CONF}/cassandra.yaml \
    ## user/dir/permmsion
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin cassandra  

COPY entrypoint.sh  /usr/local/bin/

WORKDIR ${CASSANDRA_HOME}

VOLUME ["${CASSANDRA_HOME}"]

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

ENTRYPOINT ["entrypoint.sh"]
CMD ["cassandra", "-f"]