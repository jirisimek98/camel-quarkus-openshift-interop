FROM registry.access.redhat.com/ubi8/ubi

ENV LANGUAGE='en_US:en'
WORKDIR /tmp

RUN curl -s https://password.corp.redhat.com/RH-IT-Root-CA.crt > /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt \
	&& update-ca-trust

# ubi8 repos contain maven 3.5 and jdk 1.8; we need something newer
RUN dnf install -y wget git zip unzip --setopt=install_weak_deps=False
RUN wget -O sdkman.sh https://get.sdkman.io && /bin/bash sdkman.sh
RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 11.0.20-tem && sdk install maven 3.8.7
ENV SDKMAN_DIR=/root/.sdkman

# install oc client
ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.13.0/openshift-client-linux-4.13.0.tar.gz oc.tar.gz
RUN tar -xaf oc.tar.gz oc && mv oc /usr/local/bin/

# these versions should be updated for every release
ENV QUARKUS_BRANCH=2.13.x
ENV QUARKUS_VERSION=2.13.8.SP1-redhat-00003
ENV QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-bom
ENV CAMEL_QUARKUS_VERSION=2.13.8.SP1-redhat-00003
ENV CAMEL_QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV CAMEL_QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-camel-bom

RUN git clone --depth=1 -b ${QUARKUS_BRANCH} https://gitlab.cee.redhat.com/jboss-fuse-qe/camel-q/camel-q-test-suite.git tests
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

# test results are in $PROJECT/target/failsafe-reports/*.xml for every PROJECT in $PROJECTS.
CMD ./oc_login.sh && source "/root/.sdkman/bin/sdkman-init.sh" && ./run.sh
