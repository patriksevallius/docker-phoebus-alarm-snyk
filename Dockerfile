# =========================================================
# First build stage: download release files and unpack them
# =========================================================
FROM alpine AS download-extract
RUN apk update && apk add tar unzip curl && rm -rf /var/cache
WORKDIR /var/cache/

RUN curl -OL https://controlssoftware.sns.ornl.gov/css_phoebus/nightly/alarm-server.zip
RUN unzip alarm-server.zip
RUN rm alarm-server.zip

RUN curl -OL https://controlssoftware.sns.ornl.gov/css_phoebus/nightly/alarm-logger.zip
RUN unzip alarm-logger.zip
RUN rm alarm-logger.zip
RUN curl -OL https://raw.githubusercontent.com/ControlSystemStudio/phoebus/master/services/alarm-logger/startup/create_alarm_index.sh
RUN curl -OL https://raw.githubusercontent.com/ControlSystemStudio/phoebus/master/services/alarm-logger/startup/create_alarm_template.sh


# =================================
# Final build target "alarm-server"
# =================================
FROM openjdk:21-slim-buster as alarm-server
COPY --from=download-extract /var/cache/alarm-server-4.6.3/service-alarm-server-4.6.3.jar /alarm-server/service-alarm-server-4.6.3.jar
COPY --from=download-extract /var/cache/alarm-server-4.6.3/lib /alarm-server/lib
WORKDIR /alarm-server
ENTRYPOINT ["java", "-jar", "/alarm-server/service-alarm-server-4.6.3.jar"]
CMD ["-list"]


# =================================
# Final build target "alarm-logger"
# =================================
FROM openjdk:21-slim-buster as alarm-logger
RUN apt-get update && apt-get install -yqq curl && rm -rf /var/cache/*
COPY --from=download-extract /var/cache/alarm-logger-4.6.3/service-alarm-logger-4.6.3.jar /alarm-logger/service-alarm-logger-4.6.3.jar
COPY --from=download-extract /var/cache/alarm-logger-4.6.3/lib /alarm-logger/lib
COPY --from=download-extract /var/cache/create_alarm_index.sh /alarm-logger
COPY --from=download-extract /var/cache/create_alarm_template.sh /alarm-logger
WORKDIR /alarm-logger
RUN chmod u+x create_alarm_index.sh create_alarm_template.sh
RUN sed -e'/^es_host=/d' -e'/^es_port=/d' -i create_alarm_index.sh create_alarm_template.sh
ENTRYPOINT ["java", "-jar", "/alarm-logger/service-alarm-logger-4.6.3.jar"]
CMD ["-list"]
