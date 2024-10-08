ARG ALPINE_VERSION="3.15"
FROM alpine:$ALPINE_VERSION AS download-base
WORKDIR /downloads
RUN echo "$(apk --print-arch)" > /arch.txt 
RUN ARCH2= && alpineArch="$(apk --print-arch)" \
    && case "${alpineArch##*-}" in \
    x86_64) ARCH2='amd64' ;; \
    aarch64) ARCH2='arm64' ;; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    echo $ARCH2 > /arch2.txt 

FROM download-base AS packages
RUN apk add --no-cache curl
RUN curl -LO https://dl.k8s.io/release/v1.29.2/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin

FROM download-base AS buildkit
ARG BUILDKIT_VERSION="v0.9.0"
RUN wget -O buildkit.tar.gz "https://github.com/moby/buildkit/releases/download/$BUILDKIT_VERSION/buildkit-$BUILDKIT_VERSION.linux-$(cat /arch2.txt).tar.gz"
RUN tar xvf buildkit.tar.gz

FROM download-base AS helm
ARG HELM_VERSION="v3.6.2"
RUN wget -O helm.tar.gz "https://get.helm.sh/helm-$HELM_VERSION-linux-$(cat /arch2.txt).tar.gz"
RUN tar xvf helm.tar.gz --strip-components 1

FROM download-base AS jenkins
ARG JENKINS_VERSION="2.319.1"
RUN wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war

# Jenkins
FROM alpine:$ALPINE_VERSION

# jenkins deps
RUN apk add --no-cache \
    bash \
    coreutils \
    jq \
    git \
    openjdk11 \
    openssh-client \
    ttf-dejavu \
    unzip 

ENV JENKINS_HOME="/data"
VOLUME ${JENKINS_HOME}
    
EXPOSE 8080

COPY --from=packages /usr/local/bin/kubectl /usr/bin/kubectl
COPY --from=buildkit /downloads/bin/buildctl /usr/bin/buildctl
COPY --from=helm /downloads/helm /usr/bin/helm
COPY --from=jenkins /downloads/jenkins.war /jenkins/jenkins.war

# COPY ./jenkins.install.UpgradeWizard.state ${JENKINS_HOME}/
# COPY ./scripts/admin.groovy ${JENKINS_HOME}/init.groovy.d/
COPY ./start.sh /
COPY ./setKubectl.sh /
RUN chmod +x /start.sh
RUN chmod +x /setKubectl.sh



# Jenkins 실행
CMD ["java", "-Duser.home=/data", "-Djenkins.install.runSetupWizard=false", "-jar", "/jenkins/jenkins.war"]
