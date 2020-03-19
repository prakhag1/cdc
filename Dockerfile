FROM maven:3.5.2-jdk-8-alpine AS MAVEN_TOOL_CHAIN
RUN apk add --no-cache git

# Build a shaded jar for Google's open sourced JDBC connector for Spanner
RUN git clone https://github.com/googleapis/java-spanner-jdbc && \
    cd java-spanner-jdbc && \
    mvn -B package -Pbuild-jdbc-driver -DskipTests

FROM debezium/connect:0.10

# Fetch and deploy Google Cloud Spanner JDBC driver
COPY --from=MAVEN_TOOL_CHAIN \
     /java-spanner-jdbc/target/google-cloud-spanner-jdbc-1.14.0.jar /kafka/libs

RUN cd /kafka/libs && \
    curl -sO https://repo1.maven.org/maven2/io/grpc/grpc-netty-shaded/1.27.2/grpc-netty-shaded-1.27.2.jar

# Fetch and deploy Kafka Connect JDBC
ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc
RUN mkdir $KAFKA_CONNECT_JDBC_DIR

RUN cd $KAFKA_CONNECT_JDBC_DIR && \
    curl -sO http://packages.confluent.io/maven/io/confluent/kafka-connect-jdbc/5.4.0/kafka-connect-jdbc-5.4.0.jar 
