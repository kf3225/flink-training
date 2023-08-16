##################################################
# Common variables
##################################################
ARG KAFKA_VERSION=3.5.0
ARG SCALA_VERSION=2.13
ARG USERNAME=kafka-user
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG JAVA_VERSION=corretto-11

##################################################
# Kafka Base Image
##################################################
FROM ubuntu:22.04 AS base

ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG JAVA_VERSION

# Create the user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
  && apt-get update \
  && apt-get install -y sudo wget curl git build-essential pkg-config \
  && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV KAFKA_OBJ_NAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV KAFKA_HOME=/home/${USERNAME}/${KAFKA_OBJ_NAME}
ENV PATH=$PATH:${KAFKA_HOME}/bin
ENV ASDF_DIR=/home/${USERNAME}/.asdf

SHELL ["/bin/bash", "-c"]

# Setup asdf
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} \
  && chmod +x ${ASDF_DIR}/asdf.sh \
  && chmod +x ${ASDF_DIR}/completions/asdf.bash \
  && echo "source ${ASDF_DIR}/asdf.sh" >> /home/${USERNAME}/.bashrc \
  && echo "source ${ASDF_DIR}/completions/asdf.bash" >> /home/${USERNAME}/.bashrc

# Setup java
RUN source ${ASDF_DIR}/asdf.sh \
  && asdf plugin-add java https://github.com/halcyon/asdf-java.git \
  && asdf install java latest:${JAVA_VERSION} \
  && asdf global java latest:${JAVA_VERSION}

# Setup kafka
RUN wget https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_OBJ_NAME}.tgz \
  && tar -xzf ${KAFKA_OBJ_NAME}.tgz \
  && rm -rf ${KAFKA_OBJ_NAME}.tgz

##################################################
# Kafka Zookeeper Image
##################################################
FROM ubuntu:22.04 AS zookeeper

ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG JAVA_VERSION
ARG MY_ID

# Create the user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
  && apt-get update \
  && apt-get install -y sudo wget gnupg software-properties-common curl git \
  && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV KAFKA_OBJ_NAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV KAFKA_HOME=/home/${USERNAME}/${KAFKA_OBJ_NAME}
ENV PATH=$PATH:${KAFKA_HOME}/bin
ENV ASDF_DIR=/home/${USERNAME}/.asdf

SHELL ["/bin/bash", "-c"]

COPY --from=base --chown=${USERNAME}:${USERNAME} /home/${USERNAME} /home/${USERNAME}
COPY --chown=${USERNAME}:${USERNAME} ./kafka-zookeeper /home/${USERNAME}

# Need to create `myid` file on dataDir for zookeeper.properties
RUN cp config/zookeeper.properties ${KAFKA_HOME}/config/zookeeper.properties \
  && mkdir -p /tmp/zookeeper \
  && echo "${MY_ID}" > /tmp/zookeeper/myid

ENTRYPOINT [ "./docker-entrypoint.sh" ]

##################################################
# Kafka Broker Image
##################################################
FROM ubuntu:22.04 AS broker

ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG JAVA_VERSION
ARG BROKER_ID

# Create the user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
  && apt-get update \
  && apt-get install -y sudo wget gnupg software-properties-common curl git \
  && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV KAFKA_OBJ_NAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV KAFKA_HOME=/home/${USERNAME}/${KAFKA_OBJ_NAME}
ENV PATH=$PATH:${KAFKA_HOME}/bin
ENV ASDF_DIR=/home/${USERNAME}/.asdf

SHELL ["/bin/bash", "-c"]

COPY --from=base --chown=${USERNAME}:${USERNAME} /home/${USERNAME} /home/${USERNAME}
COPY --chown=${USERNAME}:${USERNAME} ./kafka-broker /home/${USERNAME}

# Setup kafka server
RUN cp config/server.properties ${KAFKA_HOME}/config/server.properties \
  && sed -i.bk -e "s/__broker_id__/${BROKER_ID}/g" ${KAFKA_HOME}/config/server.properties \
  && source ${ASDF_DIR}/asdf.sh \
  && kafka-storage.sh format -t $(kafka-storage.sh random-uuid) -c ${KAFKA_HOME}/config/kraft/server.properties

ENTRYPOINT [ "./docker-entrypoint.sh" ]

##################################################
# Kafka Producer Image
##################################################
FROM ubuntu:22.04 AS producer

ARG KAFKA_VERSION
ARG SCALA_VERSION
ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG JAVA_VERSION

# Create the user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
  && apt-get update \
  && apt-get install -y sudo wget gnupg software-properties-common curl git \
  && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV KAFKA_OBJ_NAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV KAFKA_HOME=/home/${USERNAME}/${KAFKA_OBJ_NAME}
ENV PATH=$PATH:${KAFKA_HOME}/bin
ENV ASDF_DIR=/home/${USERNAME}/.asdf

SHELL ["/bin/bash", "-c"]

COPY --from=base --chown=${USERNAME}:${USERNAME} /home/${USERNAME} /home/${USERNAME}
COPY --chown=${USERNAME}:${USERNAME} ./kafka-producer /home/${USERNAME}

ENTRYPOINT [ "sleep", "infinity" ]
