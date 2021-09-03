FROM adoptopenjdk/openjdk8-openj9:alpine-slim
ENV TZ=Asia/Shanghai
ENV SERVER_PORT=8080
ENV PROFILES_ACTIVE=pro
ENV RUN_IN_DOCKER=true

WORKDIR /usr/local/springboot/

COPY repositories /etc/apk/repositories
COPY run.sh jvm-options.sh boot.properties arthas-boot.jar /usr/local/springboot/
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && chmod 755 *.sh

RUN apk add --no-cache bash \
        bash-doc \
        bash-completion \
        && rm -rf /var/cache/apk/* \
        && /bin/bash

COPY simsun.ttc /usr/share/fonts/simsun.ttc
RUN  apk --no-cache add ttf-dejavu fontconfig && fc-cache -f

CMD ./run.sh app start $SERVER_PORT