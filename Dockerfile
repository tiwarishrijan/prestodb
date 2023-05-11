FROM --platform=linux/amd64 openjdk:8-jre

RUN mkdir -p /opt
RUN apt-get update &&  apt-get install -y wget python less

RUN keytool -genkeypair -alias presto-db -keypass changeit -storepass changeit -keyalg RSA -keystore ${JAVA_HOME}/lib/security/cacerts -keysize 2048 -storetype JKS -dname "CN=presto-db, OU=Lumenore, O=Unknown, L=Unknown, ST=MP, C=IN"

ARG PRESTO_VERSION

# Set the URL to download
ARG PRESTO_BIN=https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz
RUN wget --quiet ${PRESTO_BIN}

RUN tar -xf presto-server-${PRESTO_VERSION}.tar.gz -C /opt
RUN rm presto-server-${PRESTO_VERSION}.tar.gz
RUN ln -s /opt/presto-server-${PRESTO_VERSION} /opt/presto

# Download the Presto CLI and put it in the image
RUN wget --quiet https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar
RUN mv presto-cli-${PRESTO_VERSION}-executable.jar /usr/local/bin/presto
RUN chmod +x /usr/local/bin/presto

ENTRYPOINT /opt/presto/bin/launcher run