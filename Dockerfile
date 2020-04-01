# Copyright 2020 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM maven:3.5.2-jdk-8-alpine AS MAVEN_TOOL_CHAIN
RUN apk add --no-cache git

# Build a shaded jar for Google's open sourced JDBC connector for Spanner
RUN git clone https://github.com/googleapis/java-spanner-jdbc && \
    cd java-spanner-jdbc && \
    mvn -B package -Pbuild-jdbc-driver -DskipTests

FROM debezium/connect:0.10

# Fetch and deploy Google Cloud Spanner JDBC driver
COPY --from=MAVEN_TOOL_CHAIN \
     /java-spanner-jdbc/target/google-cloud-spanner-jdbc-*-SNAPSHOT.jar /kafka/libs

RUN cd /kafka/libs && \
    curl -sO https://repo1.maven.org/maven2/io/grpc/grpc-netty-shaded/1.27.2/grpc-netty-shaded-1.27.2.jar

# Fetch and deploy Kafka Connect JDBC
ENV KAFKA_CONNECT_JDBC_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-jdbc
RUN mkdir $KAFKA_CONNECT_JDBC_DIR

RUN cd $KAFKA_CONNECT_JDBC_DIR && \
    curl -sO http://packages.confluent.io/maven/io/confluent/kafka-connect-jdbc/5.4.0/kafka-connect-jdbc-5.4.0.jar 

# Fetch BQ connector
ENV KAFKA_BQ_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-bq
RUN mkdir $KAFKA_BQ_DIR

RUN cd $KAFKA_BQ_DIR && \
    curl -sO http://client.hub.confluent.io/confluent-hub-client-latest.tar.gz && \
    tar -xvf confluent-hub* && \
    ./bin/confluent-hub install --no-prompt wepay/kafka-connect-bigquery:latest && \
    cp share/confluent-hub-components/*/lib/* .
     
