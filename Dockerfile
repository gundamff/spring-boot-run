FROM java:8
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
COPY run.sh jvm-options.sh boot.properties /usr/local/springboot/

WORKDIR /usr/local/springboot/
CMD ["./run.sh","app","start"]
