FROM ubuntu:20.04 AS stage-atlas

ENV ATLAS_VERSION 2.3.0
ENV TARBALL apache-atlas-${ATLAS_VERSION}-sources.tar.gz
ENV	MAVEN_OPTS	"-Xms2g -Xmx2g"

RUN mkdir -p /tmp/atlas-src \
    && mkdir -p /apache-atlas \
    && mkdir -p /gremlin

COPY pom.xml.patch /tmp/atlas-src/

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install apt-utils \
    && apt-get -y install \
        maven \
        wget \
        python \
        openjdk-8-jdk-headless \
        patch \
        unzip \
    && cd /tmp \
    && wget https://dlcdn.apache.org/atlas/${ATLAS_VERSION}/apache-atlas-${ATLAS_VERSION}-sources.tar.gz \
    && tar --strip 1 -xzvf apache-atlas-${ATLAS_VERSION}-sources.tar.gz -C /tmp/atlas-src \
    && rm apache-atlas-${ATLAS_VERSION}-sources.tar.gz \
    && cd /tmp/atlas-src \
    && sed -i 's/http:\/\/repo1.maven.org\/maven2/https:\/\/repo1.maven.org\/maven2/g' pom.xml \
    && patch -b -f < pom.xml.patch \
    && mvn clean \
        -Dmaven.repo.local=/tmp/atlas-src/.mvn-repo \
        -Dhttps.protocols=TLSv1.2 \
        -DskipTests \
        -Drat.skip=true \
        package -Pdist

RUN mv distro/target/apache-atlas-*-bin.tar.gz /apache-atlas.tar.gz \
	&& mv distro/target/apache-atlas-*-kafka-hook.tar.gz /apache-atlas-kafka-hook.tar.gz \
	&& mv distro/target/apache-atlas-*-hive-hook.tar.gz /apache-atlas-hive-hook.tar.gz \
	&& mv distro/target/apache-atlas-*-sqoop-hook.tar.gz /apache-atlas-sqoop-hook.tar.gz

FROM centos:7

COPY --from=stage-atlas /apache-atlas.tar.gz /apache-atlas.tar.gz
COPY --from=stage-atlas /apache-atlas-kafka-hook.tar.gz /apache-atlas-kafka-hook.tar.gz
COPY --from=stage-atlas /apache-atlas-hive-hook.tar.gz /apache-atlas-hive-hook.tar.gz
COPY --from=stage-atlas /apache-atlas-sqoop-hook.tar.gz /apache-atlas-sqoop-hook.tar.gz

# install which - GUS 10.5
RUN yum update -y  \
	&& yum install -y python python37 && yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel patch net-tools -y \
	&& yum install which -y \
	&& yum clean all
RUN groupadd hadoop && \
	useradd -m -d /opt/atlas -g hadoop atlas

RUN pip3 install amundsenatlastypes

USER atlas

RUN cd /opt \
	&& tar xzf /apache-atlas.tar.gz -C /opt/atlas --strip-components=1

COPY model /tmp/model
COPY resources/atlas-setup.sh /tmp
COPY resources/credentials /tmp
COPY resources/init_amundsen.py /tmp

COPY resources/atlas-application.properties /opt/atlas/conf/

USER root
ADD resources/entrypoint.sh /entrypoint.sh
RUN rm -rf /apache-atlas.tar.gz

USER atlas

ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]

EXPOSE 21000
