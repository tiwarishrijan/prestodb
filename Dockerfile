FROM --platform=linux/amd64 openjdk:8-jre

RUN mkdir -p /opt
RUN apt-get update &&  apt-get install -y wget python less

COPY presto-db.jks /tmp
RUN keytool -importkeystore -srckeystore /tmp/presto-db.jks -destkeystore ${JAVA_HOME}/lib/security/cacerts -srcstorepass changeit -deststorepass changeit -noprompt

ARG PRESTO_VERSION

# Set the URL to download
ARG PRESTO_BIN=https://repo1.maven.org/maven2/com/facebook/presto/presto-server/${PRESTO_VERSION}/presto-server-${PRESTO_VERSION}.tar.gz
RUN wget ${PRESTO_BIN} 
RUN tar -xf presto-server-${PRESTO_VERSION}.tar.gz -C /opt
RUN ln -s /opt/presto-server-${PRESTO_VERSION} /opt/presto && rm presto-server-${PRESTO_VERSION}.tar.gz

# Download the Presto CLI and put it in the image
RUN wget  https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/${PRESTO_VERSION}/presto-cli-${PRESTO_VERSION}-executable.jar -O /usr/local/bin/presto/presto-cli-${PRESTO_VERSION}-executable.jar && chmod +x /usr/local/bin/presto

ENTRYPOINT /opt/presto/bin/launcher run