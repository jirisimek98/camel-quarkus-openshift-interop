#!/bin/bash
set -eux

export _JAVA_OPTIONS=-Duser.home=$HOME

mvn -B -V clean install -fae -Dformat.skip=true -am -Dquarkus.openshift.build-log-level=DEBUG -ntp -Dts.global.log.nocolor=true \
    -Dmaven.repo.local=$PWD/local-repo \
    -Dquarkus.platform.group-id=$QUARKUS_PLATFORM_GROUP_ID \
    -Dquarkus.platform.artifact-id=$QUARKUS_PLATFORM_ARTIFACT_ID \
    -Dquarkus.platform.version=$QUARKUS_VERSION \
    -Dcamel-quarkus.platform.group-id=$CAMEL_QUARKUS_PLATFORM_GROUP_ID \
    -Dcamel-quarkus.platform.artifact-id=$CAMEL_QUARKUS_PLATFORM_ARTIFACT_ID \
    -Dcamel-quarkus.platform.version=$CAMEL_QUARKUS_VERSION \
    -Dopenshift \
    -Pocp-interop
