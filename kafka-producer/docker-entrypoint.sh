#!/bin/bash

source "${ASDF_DIR}/asdf.sh"
kafka-topics.sh --create --topic quickstart-events --bootstrap-server broker-1:9092
