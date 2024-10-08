FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/openjdk-21

ENV LANGUAGE='en_US:en'

ENV SDKMAN_DIR=/root/.sdkman
ENV PATH=$SDKMAN_DIR/candidates/maven/current/bin:$PATH
# install Maven 3.8.x where x >= 6
ENV MAVEN_VERSION=3.8.7
# install oc cli v4.15 due to compatibility with ubi8
ENV OC_CLIENT_VERSION=4.15.9

WORKDIR /tmp

# user jboss doesn't have priviledges to install packages
USER root
# Zip / Unzip is needed for sdkman
RUN microdnf install -y git zip unzip &&\
	curl https://get.sdkman.io -o sdkman.sh &&\
	/bin/bash sdkman.sh &&\
	source "${SDKMAN_DIR}/bin/sdkman-init.sh" &&\
	sdk install maven "${MAVEN_VERSION}" &&\
	curl -s https://certs.corp.redhat.com/certs/2022-IT-Root-CA.pem > /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt &&\
	update-ca-trust &&\
	curl "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_CLIENT_VERSION}/openshift-client-linux-${OC_CLIENT_VERSION}.tar.gz" -o oc.tar.gz &&\
	tar -xaf oc.tar.gz oc &&\
	mv oc /usr/local/bin/ &&\
	mkdir --mode=777 /tmp/home &&\
	# Without this we got "read-only file system" bug during CI test runs
	chgrp -R 0 /var &&\
	chmod -R g=u /var &&\
	microdnf clean all &&\
	[ ! -d /var/cache/yum ] || rm -rf /var/cache/yum

# these versions should be updated for every release
ENV CAMEL_QUARKUS_TS_BRANCH=3.8.x
ENV QUARKUS_VERSION=3.8.6.redhat-00005
ENV QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-bom
ENV CAMEL_QUARKUS_VERSION=3.8.6.redhat-00005
ENV CAMEL_QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform
ENV CAMEL_QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-camel-bom

ENV PROJECTS=mounts,ocp-interaction-layers/configmap-secret

ENV HOME=/tmp/home

RUN git clone --depth=1 -b ${CAMEL_QUARKUS_TS_BRANCH} https://gitlab.cee.redhat.com/jboss-fuse-qe/camel-q/camel-q-test-suite.git tests &&\
	chmod -R 777 /tmp/tests

WORKDIR /tmp/tests

# maven settings for repository
ADD settings.xml /tmp/home/.m2/settings.xml

ADD --chmod=755 run.sh oc_login.sh /tmp/tests/
# to debug on local
# ADD --chmod=755 oc_login_local.sh /tmp/tests/oc_login.sh

USER jboss

# test results are in $PROJECT/target/failsafe-reports/*.xml for every PROJECT in $PROJECTS.
CMD ./oc_login.sh && ./run.sh
