FROM debian:stretch

RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/getzola/zola/releases/download/v0.5.1/zola-v0.5.1-x86_64-unknown-linux-gnu.tar.gz && \
    tar -xvf zola-v0.5.1-x86_64-unknown-linux-gnu.tar.gz && \
    rm -f zola-v0.5.1-x86_64-unknown-linux-gnu.tar.gz && \
    chmod +x zola && mv zola /usr/bin/zola
ADD spacebrook.dev/ /spacebrook.dev
RUN cd /spacebrook.dev && zola build

FROM debian:stretch
ENTRYPOINT ["/usr/sbin/nginx", "-c", "/nginx.conf"]
EXPOSE 80 443

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists

# Generate self-signed SSL certs.
RUN mkdir -p /etc/letsencrypt/live/spacebrook.dev && \
    cd /etc/letsencrypt/live/spacebrook.dev && \
    openssl req -x509 -nodes -newkey rsa:4096 -sha256 \
                -keyout privkey.pem -out fullchain.pem \
                -days 36500 -subj '/CN=localhost' && \
    openssl dhparam -dsaparam -out dhparam.pem 4096

ADD nginx.conf /nginx.conf
COPY --from=0 /spacebrook.dev/public /public
