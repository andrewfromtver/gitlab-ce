FROM gitlab/gitlab-runner:alpine3.18-v16.1.0

# set LANG env var
ENV LANG=C.UTF-8

#add Glibc 2.34 for Alpine linux
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.34-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    mv /etc/nsswitch.conf /etc/nsswitch.conf.bak && \
    apk add --no-cache --force-overwrite \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    mv /etc/nsswitch.conf.bak /etc/nsswitch.conf && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    (/usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true) && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# set env vars
ENV ANDROID_SDK_ROOT "/opt/sdk"
ENV ANDROID_HOME ${ANDROID_SDK_ROOT}
ENV PATH $PATH:${ANDROID_SDK_ROOT}/gradle/6.5/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest_supported/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/extras/google/instantapps:${ANDROID_SDK_ROOT}/build-tools/34.0.0

# add core apps and libs (jdk8, jdk11, cordova10)
RUN apk add --no-cache --update \
    docker docker-compose openrc doas nodejs-current npm curl python3 python3-dev py3-pip gcc musl-dev openjdk8 openjdk11 curl unzip wget
RUN python3 -m pip install --upgrade --no-cache semgrep && \
    npm install -g cordova@10
RUN rc-update add docker boot
RUN echo 'permit nopass gitlab-runner as root' > /etc/doas.d/doas.conf

# add Gradle 6.5
RUN wget -q https://services.gradle.org/distributions/gradle-6.5-all.zip -O /tmp/gradle.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/gradle && \
    unzip -qq /tmp/gradle.zip -d ${ANDROID_SDK_ROOT}/gradle && \
    mv ${ANDROID_SDK_ROOT}/gradle/* ${ANDROID_SDK_ROOT}/gradle/6.5 && \
    rm -v /tmp/gradle.zip

# add latest android command line tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/tools.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    unzip -qq /tmp/tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/latest_supported && \
    rm -v /tmp/tools.zip && \
    mkdir -p ~/.android/ && touch ~/.android/repositories.cfg

# add android platform tools, build tools 34.0.0
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "extras;google;instantapps" "build-tools;34.0.0"

# remove jdk11
RUN apk del openjdk11

# fix build tools "dx" bug
RUN mv /opt/sdk/build-tools/34.0.0/d8 /opt/sdk/build-tools/34.0.0/dx &&\
    mv /opt/sdk/build-tools/34.0.0/lib/d8.jar /opt/sdk/build-tools/34.0.0/lib/dx.jar

# set ownership of android sdk to gitlab-runner user
RUN chown gitlab-runner -R /opt/sdk

# set default jdk to jdk8
ENV JAVA_HOME "/usr/lib/jvm/java-1.8-openjdk"
ENV PATH $PATH:${JAVA_HOME}/bin
