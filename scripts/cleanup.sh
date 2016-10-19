#!/bin/sh -ex

cat /etc/ssh/sshd_config
rm -f /etc/ssh/ssh_host*

fstrim -v / || echo dummy

