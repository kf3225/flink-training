#!/bin/bash

source "${ASDF_DIR}/asdf.sh"
zookeeper-server-start.sh "${KAFKA_HOME}/config/zookeeper.properties"
