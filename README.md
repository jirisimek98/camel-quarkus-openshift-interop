# Openshift CI

Folder `openshift-ci` in this repo contains files, required for OpenShift CI.
It allows us to verify, that released Camel Quarkus works on a new version of Openshift.

## How it works

The tests are run regularly (every Monday at the time of writing). Test execution is based on configs: [[1]](https://github.com/openshift/release),[[2]](https://github.com/openshift/release/pull/40279/files).

During the run CI takes the Dockerfile from `openshift-ci` folder, builds an image from it and runs tests from [Camel Quarkus TS](https://gitlab.cee.redhat.com/jboss-fuse-qe/camel-q/camel-q-test-suite) modules defined by `$PROJECTS` variable.

Results are posted into [quarkus-qe](https://redhat-internal.slack.com/archives/C05CMLUAWTT) channel in Slack and new issue in [QQE Jira](https://issues.redhat.com/projects/QQE/summary) is created automatically for every failure. Job history can be accessed from the [Prow Dashboard](https://prow.ci.openshift.org/job-history/gs/origin-ci-test/logs/periodic-ci-quarkus-qe-quarkus-test-suite-main-quarkus-ocp4.14-lp-interop-quarkus-interop-aws) or via [dashboard](https://testgrid.k8s.io/redhat-openshift-lp-interop-release-4.14-informing#periodic-ci-quarkus-qe-quarkus-test-suite-main-quarkus-ocp4.14-lp-interop-quarkus-interop-aws&width=90).

## Requirements
### Released version of Camel Quarkus
Due to the nature of tests, only the released bits are used. These are pulled directly from the maven.repository.redhat.com, not from an internal source, to be as close to real customer use-case as possible. This means that new versions of Camel Quarkus can only be tested once the release is done and the artifacts are in the maven repository.

### OpenShift requirements
There are no specific requirement on OpenShift installation, but pull secret for dockerhub is highly recommended to avoid pull rate limiting.

### Test machine requirements
All the required libraries are installed as part of the scenario:
- Git
- Java 17 OpenJDK
- Maven
- Docker/Podman/Buildah

## Processes
### Contacting PIT team
- Email: [pit-qe@redhat.com](mailto:pit-qe@redhat.com)
- Jira: [INTEROP project](https://projects.engineering.redhat.com/browse/INTEROP)
- Slack: [#forum-qe-layered-product](https://redhat-internal.slack.com/archives/C04QDE5TK1C)

### New version of Camel Quarkus
After a new version of Quarkus is released, you should do the following:
- Update this section of Dockerfile (description is in the comments):
```asciidoc
ENV CAMEL_QUARKUS_BRANCH=2.13.x # branch in of the repo which is used to run tests
ENV QUARKUS_VERSION=2.13.8.SP1-redhat-00003 # version of Quarkus BOM associated with the release
ENV QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform # group of Quarkus BOM. Unlikely to change
ENV QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-bom # name of Quarkus BOM. Unlikely to change
ENV CAMEL_QUARKUS_VERSION=2.13.8.SP1-redhat-00003 # version of Camel Quarkus BOM associated with the release
ENV CAMEL_QUARKUS_PLATFORM_GROUP_ID=com.redhat.quarkus.platform # group of Camel Quarkus BOM. Unlikely to change
ENV CAMEL_QUARKUS_PLATFORM_ARTIFACT_ID=quarkus-camel-bom # name of Camel Quarkus BOM. Unlikely to change
```
- Update to preferred JDK in Dockerfile (base image FROM)
- Update ocp client in Dockerfile version to latest released OCP (find at https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/)
- Try to run it locally (see [How to run locally#Without OCP deployment](#without-ocp-deployment)) and verify it passes
- [Create image and push it to quay.io](#create-an-image)
- [Ensure the image works in OpenShift CI](#how-to-verify-image-is-working-at-openshift-ci)

**NOTE:** For now, Interop team supports only one job for every product, so we only test the latest CEQ release. They plan to keep N-1 (eg. 4.14.x) and N-2 (eg. 4.13.x) OpenShift certifications, but it should be INTEROP team responsibility.

### Adding new tests
Currently, the list of modules to be run is defined in the run script in `PROJECTS` variable. If you want additional tests to be run, update the list of modules (don't forget to add dependent modules if applicable).
You should only add stable tests without random failures to the list! Once done follow the same steps mentioned above (starting from `Try to run it locally`).

## Create an image
### Create image
```
docker build -t quay.io/rh_integration/camel-quarkus-qe-test-container:latest .
```
### Push image
**_NOTE:_** You have to be first logged in to quay.io. You can find under _Account settings/User settings/Docker CLI Password/Generate Encrypted password_ at quay.io.
```
docker push quay.io/rh_integration/camel-quarkus-qe-test-container:latest
```
Verify it is present at https://quay.io/repository/rh_integration/camel-quarkus-qe-test-container?tab=tags 

## How to verify image is working at OpenShift CI
You have to firstly decide which strategy we follow. 
If we are using `:latest` tag of test images for all tested OpenShift versions or we have multiple different tags. 
At the time of writing this docs, we are using `:latest` tag, as we are testing only latest supported GA version of Camel Quarkus product.

You can check it in one of `.yaml` file in https://github.com/openshift/release/tree/master/ci-operator/config/jboss-fuse/camel-quarkus-openshift-interop eg. in https://github.com/openshift/release/blob/master/ci-operator/config/jboss-fuse/camel-quarkus-openshift-interop/jboss-fuse-camel-quarkus-openshift-interop-main__camel-quarkus-ocp4.15-lp-interop.yaml#L5

You should see similar:

````
base_images:
  camel-quarkus-runner:
    name: camel-quarkus-qe-test-container
    namespace: ci
    tag: latest
````

### Using :latest tag
You can submit a WIP PR [example](https://github.com/llowinge/release/commit/2dd7846900fb52a039d8129c2ece713a26e69985) to https://github.com/openshift/release that's putting a minor change on the test script for example echo command. 
Once the automation recognized the job will be affected from the PR, you'll be able to run rehearse.

You can do it with commenting eg. `/pj-rehearse periodic-ci-jboss-fuse-camel-quarkus-openshift-interop-main-camel-quarkus-ocp4.15-lp-interop-camel-quarkus-interop-aws`

After green test results, you should ack it with `/pj-rehearse ack` and waiting for PR being merged - if it takes too much time, you can approach Slack [#forum-qe-layered-product](https://redhat-internal.slack.com/archives/C04QDE5TK1C).

### Using custom tag
In the past we were testing two versions of GA product. 
It was 2.13 and 3.2. 
To differentiate we were using different tags of test image. 
For example `2.13.x-openjdk11` and `3.2.x-openjdk17`. 
If it would re-happen again, we would have to communicate it with INTEROP team so they create more `.yaml` files.

In such case the theoretical steps should be:

* Creating PR with new tag added to https://github.com/openshift/release/blob/master/core-services/image-mirroring/supplemental-ci-images/mapping_supplemental_ci_images_ci#L129
* After merged, creating another PR with changes to `.yaml` files (probably with help of INTEROP team)


## How to run locally
### Without OCP deployment
**_NOTE:_** This is easier approach, but it is not 100% accurate to what happens on OpenShift CI. But usually such verification is enough.

Docker command below will build the image. Then it will run the container, which first logs into your OpenShift, clones testsuite and then run Maven execution of tests. So you will verify that the image works (but you are not running it in OpenShift, so it is not 100% safe way). 

- Change `oc_login.sh` file to login to your existing OCP cluster.
- Go to `openshift-ci folder` and run:
```
docker build -t camel-quarkus-openshift-interop . && docker run camel-quarkus-openshift-interop | tee output.txt
```
### With OCP deployment
- Change `oc_login.sh` file to login to your existing OCP cluster.
- Create a new public Docker repository (eg `quay.io/$USER/test-container`)
- Build and save an image for testing (you can use Docker, Podman or Buildah):
```
podman build --tag=quay.io/$USER/test-container -f openshift-ci/Dockerfile
podman push quay.io/$USER/test-container
```
- Run the tests:
```
oc create deployment interop-container --image=quay.io/$USER/test-container
```
- Clean after yourself:
```
oc delete deployment interop-container
```
