#!/bin/bash -e

# Script to initially setup the server.

sudo apt-get update
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install -y docker-ce
sudo apt-get install -y htop ncdu tree vim

cat << 'EOF' > upgrade.sh
#!/bin/bash -e

TAG=$1
if [[ "$TAG" == "" ]]; then
    echo "Please enter an argument with the docker tag to upgrade to."
    exit 1
fi

sudo docker pull spacebrook/spacebrook.dev:$TAG
sudo docker tag spacebrook/spacebrook.dev:$TAG spacebrook.dev
sudo docker rm -f spacebrook.dev || true
sudo docker run \
    -v /root/www:/app/www/ \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -p 80:80 \
    -p 443:443 --name spacebrook.dev -d spacebrook.dev
echo "Tailing logs..."
sudo docker logs -f spacebrook.dev
EOF
chmod +x upgrade.sh

cat << 'EOF' > cleanup.sh
#!/bin/bash -e

sudo docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:rw \
  -v /var/lib/docker:/var/lib/docker:rw \
  --restart always \
  --detach \
  meltwater/docker-cleanup:latest
EOF
chmod +x cleanup.sh

cat << 'EOF' > pre-ssl.sh
#!/bin/bash -e

sudo docker rm -f spacebrook.dev || true
sudo docker run \
    -v /root/www:/app/www/ \
    -p 80:80 \
    -p 443:443 --name spacebrook.dev -d spacebrook.dev
EOF
chmod +x pre-ssl.sh

sudo ./cleanup.sh

echo "Run ./upgrade.sh with the latest version."

# Notes
# Everything is installed in /root

# Cert setup:
# echo deb http://ftp.debian.org/debian stretch-backports main >> /etc/apt/sources.list
# sudo apt-get update
# sudo apt-get install -y certbot
#
# Run the server without ssl certs:
# Pull the image and tag it as spacebrook.dev
# Run pre-ssl.sh
#
# Set up the cert:
# letsencrypt certonly --webroot-path /root/www
#
# Generate the dhparam:
# openssl dhparam -dsaparam -out /etc/letsencrypt/live/spacebrook.dev/dhparam.pem 4096
#
# Then, install cert crontab as root:
# sudo su -
# crontab -e
# 0 4 * * * letsencrypt renew --webroot-path /root/www >> /var/log/letsencrypt.log
#
# Test cert generation:
# letsencrypt renew --dry-run
#
# Now you can release with make release
