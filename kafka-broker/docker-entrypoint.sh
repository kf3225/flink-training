#!/bin/bash

source "${ASDF_DIR}/asdf.sh"
kafka-server-start.sh "${KAFKA_HOME}/config/server.properties"
