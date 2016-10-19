#!/bin/sh -ex

if [ "x$(uname -m)" = "x86_64" ]; then
    curl -Lk https://github.com/aelsabbahy/goss/releases/download/v0.2.4/goss-linux-amd64 --output /usr/local/bin/goss
else
    curl -Lk https://github.com/aelsabbahy/goss/releases/download/v0.2.4/goss-linux-386 --output /usr/local/bin/goss
fi
chmod +x /usr/local/bin/goss
/usr/local/bin/goss -g /tmp/goss.yaml validate --format documentation
rm -f /tmp/goss.yaml /usr/local/bin/goss
