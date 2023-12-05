FROM registry.access.redhat.com/ubi8/openjdk-11

ENV LANGUAGE='en_US:en'
WORKDIR /tmp

# user jboss doesn't have priviledges to install packages
USER root 
RUN microdnf install -y wget git zip unzip

# install Maven 3.8.x where x >= 6
ENV SDKMAN_DIR=/root/.sdkman
RUN wget -O sdkman.sh https://get.sdkman.io && /bin/bash sdkman.sh
RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install maven 3.8.7
ENV PATH=$SDKMAN_DIR/candidates/maven/current/bin:$PATH

RUN curl -s https://password.corp.redhat.com/RH-IT-Root-CA.crt > /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt \
	&& update-ca-trust

# install oc client
ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.13.0/openshift-client-linux-4.13.0.tar.gz oc.tar.gz
RUN tar -xaf oc.tar.gz oc && mv oc /usr/local/bin/

# these versions should be updated for every release
ENV CAMEL_QUARKUS_TS_BRANCH=2.13.x
ENV QUARKUS_VERSION=2.13.8.SP1-redhat-00003
ENV QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-bom
ENV CAMEL_QUARKUS_VERSION=2.13.8.SP1-redhat-00003
ENV CAMEL_QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV CAMEL_QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-camel-bom

ENV PROJECTS=mounts,ocp-interaction-layers/configmap-secret

RUN git clone --depth=1 -b ${CAMEL_QUARKUS_TS_BRANCH} https://gitlab.cee.redhat.com/jboss-fuse-qe/camel-q/camel-q-test-suite.git tests
WORKDIR /tmp/tests
RUN chmod -R 777 /tmp/tests

RUN mkdir --mode=777 /tmp/home
ENV HOME=/tmp/home

# maven settings for repository
ADD settings.xml /tmp/home/.m2/settings.xml

ADD --chmod=755 run.sh /tmp/tests/
ADD --chmod=755 oc_login.sh /tmp/tests/
# to debug on local
# ADD --chmod=755 oc_login_local.sh /tmp/tests/oc_login.sh

# Without this we got "read-only file system" bug during CI test runs
RUN chgrp -R 0 /var && chmod -R g=u /var
RUN microdnf clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum
USER jboss

# test results are in $PROJECT/target/failsafe-reports/*.xml for every PROJECT in $PROJECTS.
CMD ./oc_login.sh && ./run.sh
