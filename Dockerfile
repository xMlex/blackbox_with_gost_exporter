FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

ADD gost.cnf /gost.cnf

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl libengine-gost-openssl \
    && rm -rf /var/lib/apt/lists/*

RUN openssl version \
    && sed -i 's/openssl_conf = openssl_init/\nopenssl_conf = openssl_gost/g' /etc/ssl/openssl.cnf \
    && cat /gost.cnf >> /etc/ssl/openssl.cnf \
    && sed -i "s#\[default_sect\]#\n\[default_sect\]\nMinProtocol\=TLSv1.2\nCipherString = DEFAULT:@SECLEVEL=1#g" /etc/ssl/openssl.cnf \
    && cat /etc/ssl/openssl.cnf \
    && echo "openssl engine gost -c" \
    && openssl engine gost -c \
    && echo "openssl ciphers" \
    && openssl ciphers | tr ':' '\n' | grep GOST

COPY --from=quay.io/prometheus/blackbox-exporter:v0.24.0 /bin/blackbox_exporter /bin/blackbox_exporter
#COPY --from=quay.io/prometheus/blackbox-exporter:v0.24.0 /etc/blackbox_exporter/config.yml /etc/blackbox_exporter/config.yml
ADD config.yml /etc/blackbox_exporter/config.yml

EXPOSE 9115

ENTRYPOINT ["/bin/blackbox_exporter"]
CMD ["--config.file=/etc/blackbox_exporter/config.yml"]
