#
#
#
FROM appsoa/docker-centos-base-java:latest

USER root

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
ENV JENKINS_UC https://updates.jenkins.io
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

ARG user=jenkins
ARG group=jenkins
ARG uid=2000
ARG gid=2000

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

COPY src/init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.32.1}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=1b65dc498ba7ab1f5cce64200b920a8716d90834

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha1sum -c -




COPY src/jenkins-support /usr/local/bin/jenkins-support
COPY src/jenkins.sh /usr/local/bin/jenkins.sh
COPY src/plugins.sh /usr/local/bin/plugins.sh
COPY src/install-plugins.sh /usr/local/bin/install-plugins.sh

RUN install-plugins.sh  git \
                        github \
                        docker \
                        kubernetes \
                        livescreenshot \
                        google-cloud-backup \
                        google-container-registry-auth \
                        google-source-plugin \
                        google-storage-plugin \
                        gcloud-sdk \
                        simple-theme-plugin

EXPOSE 8080 50000

RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins

USER ${user}

ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
