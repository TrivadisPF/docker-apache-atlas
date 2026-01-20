# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:20.04

ARG TARGETARCH
ARG ATLAS_BASE_JAVA_VERSION=8

# Install tzdata, Python, Java
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata vim\
    python3 python3-pip openjdk-8-jdk openjdk-11-jdk openjdk-17-jdk bc iputils-ping ssh pdsh

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-${ATLAS_BASE_JAVA_VERSION}-openjdk-${TARGETARCH}
ENV ATLAS_DIST=/home/atlas/dist
ENV ATLAS_HOME=/opt/atlas
ENV ATLAS_SCRIPTS=/home/atlas/scripts
ENV PATH=/usr/java/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN update-java-alternatives --set /usr/lib/jvm/java-1.${ATLAS_BASE_JAVA_VERSION}.0-openjdk-${TARGETARCH}

# setup groups, users, directories
RUN groupadd atlas && \
    useradd -g atlas -ms /bin/bash atlas && \
    groupadd hadoop && \
    useradd -g hadoop -ms /bin/bash hdfs && \
    useradd -g hadoop -ms /bin/bash yarn && \
    useradd -g hadoop -ms /bin/bash hive && \
    useradd -g hadoop -ms /bin/bash hbase && \
    useradd -g hadoop -ms /bin/bash kafka && \
    mkdir -p /home/atlas/dist && \
    mkdir -p /home/atlas/scripts && \
    chown -R atlas:atlas /home/atlas


ARG ATLAS_BACKEND=hbase
ARG ATLAS_SERVER_JAVA_VERSION=8
ARG ATLAS_VERSION=2.4.0
ARG TARGETARCH

ENV JAVA_HOME=/usr/lib/jvm/java-${ATLAS_SERVER_JAVA_VERSION}-openjdk-${TARGETARCH}
RUN update-java-alternatives --set /usr/lib/jvm/java-1.${ATLAS_SERVER_JAVA_VERSION}.0-openjdk-${TARGETARCH}

COPY ./scripts/atlas.sh                                 ${ATLAS_SCRIPTS}/
COPY ./dist/apache-atlas-${ATLAS_VERSION}-server.tar.gz /home/atlas/dist/

RUN tar xfz /home/atlas/dist/apache-atlas-${ATLAS_VERSION}-server.tar.gz --directory=/opt/ && \
    ln -s /opt/apache-atlas-${ATLAS_VERSION} ${ATLAS_HOME} && \
    rm -f /home/atlas/dist/apache-atlas-${ATLAS_VERSION}-server.tar.gz && \
    mkdir -p /var/run/atlas /var/log/atlas /home/atlas/data ${ATLAS_HOME}/hbase/conf && \
    rm -rf ${ATLAS_HOME}/logs && \
    ln -s /var/log/atlas ${ATLAS_HOME}/logs && \
    ln -s /home/atlas/data ${ATLAS_HOME}/data && \
    chown -R atlas:atlas ${ATLAS_HOME}/ /var/run/atlas/ /var/log/atlas/

COPY ./scripts/hbase-site.xml ${ATLAS_HOME}/hbase/conf/

VOLUME /home/atlas/data

EXPOSE 21000

ENTRYPOINT [ "/home/atlas/scripts/atlas.sh" ]