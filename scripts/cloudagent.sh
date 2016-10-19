#!/bin/sh -x

URL="http://cdn.selfip.ru/public/cloudagent"
ARCH="x86_32"
SUDO="$(which sudo)"
BIN=""

case "$(uname -m)" in
    "x86_64")
        ARCH="x86_64"
        ;;
esac

case "$(uname)" in
    "Linux")
        BIN="/opt/bin/cloudagent"
        URL="${URL}-linux-${ARCH}"
        ;;
    "FreeBSD")
        BIN="/usr/local/opt/bin/cloudagent"
        URL="${URL}-freebsd-${ARCH}"
        ;;
esac

install_centos() {
set -e
get_cloudagent_bin

echo '#!/bin/bash
#
# cloudagent     This shell script takes care of starting and stopping
#                cloudagent.
#
# chkconfig: - 58 74
# description: cloudagent. \

### BEGIN INIT INFO
# Provides: cloudagent
# Required-Start: $local_fs
# Required-Stop: $local_fs
# Should-Start:
# Should-Stop:
# Short-Description: start and stop cloudagent
# Description: cloudagent is the cloudagent
### END INIT INFO

# Source function library.
. /etc/init.d/functions

prog=cloudagent
lockfile=/var/lock/subsys/$prog

start() {
        [ "$EUID" != "0" ] && exit 4
        [ -x /opt/bin/cloudagent ] || exit 5

        # Start daemons.
        echo -n $"Starting $prog: "
        $prog &
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch $lockfile
        return $RETVAL
}

stop() {
        [ "$EUID" != "0" ] && exit 4
        echo -n $"Shutting down $prog: "
        killproc $prog
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $lockfile
        return $RETVAL
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status $prog
        ;;
  restart|force-reload)
        stop
        start
        ;;
  try-restart|condrestart)
        if status $prog > /dev/null; then
            stop
            start
        fi
        ;;
  reload)
        exit 3
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart|try-restart|force-reload}"
        exit 2
esac
' | $SUDO tee /etc/init.d/cloudagent
$SUDO chmod +x /etc/init.d/cloudagent
$SUDO chkconfig cloudagent on
set +e
}

install_debian() {
set -e
get_cloudagent_bin

echo '#!/bin/sh

### BEGIN INIT INFO
# Provides:        cloudagent
# Required-Start:  $local_fs
# Required-Stop:   $local_fs
# Default-Start:   2 3 4 5
# Default-Stop:
# Short-Description: Start cloudagent
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

. /lib/lsb/init-functions

DAEMON=/opt/bin/cloudagent
PIDFILE=/var/run/cloudagent.pid

test -x $DAEMON || exit 5

case $1 in
    start)
       log_daemon_msg "Starting cloudagent" "cloudagent"
       start-stop-daemon --start --quiet --oknodo --pidfile $PIDFILE --background --startas $DAEMON
       log_end_msg $?
       ;;
    stop)
       log_daemon_msg "Stopping cloudagent" "cloudagent"
       start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
       log_end_msg $?
       ;;
    restart|force-reload)
       $0 stop && sleep 2 && $0 start
       ;;
    try-restart)
       if $0 status >/dev/null; then
           $0 restart
       else
           exit 0
       fi
       ;;
     reload)
       exit 3
       ;;
     status)
       status_of_proc $DAEMON "cloudagent"
       ;;
     *)
       echo "Usage: $0 {start|stop|restart|try-restart|force-reload|status}"
       exit 2
       ;;
esac
' | $SUDO tee /etc/init.d/cloudagent
$SUDO chmod +x /etc/init.d/cloudagent
$SUDO update-rc.d cloudagent defaults


set +e
}

install_bsd() {
set -e
echo '#!/bin/sh
#
#

# PROVIDE: cloudagent
# REQUIRE: LOGIN FILESYSTEMS
# KEYWORD: shutdown

. /etc/rc.subr

name="cloudagent"
rcvar="cloudagent_enable"
stop_cmd=":"
start_cmd="cloudagent_start"

cloudagent_start()
{
    /usr/local/opt/bin/cloudagent &
}

load_rc_config $name
run_rc_command "$1"
' | $SUDO tee /usr/local/etc/rc.d/cloudagent
$SUDO chmod +x /usr/local/etc/rc.d/cloudagent
echo 'cloudagent_enable="YES"' | $SUDO tee -a /etc/rc.conf
set +e
}

install_upstart() {
set -e
get_cloudagent_bin

echo '# cloudagent
start on (local-filesystems)

#console log

exec /opt/bin/cloudagent
' | $SUDO tee /etc/init/cloudagent.conf
set +e
}

install_systemd() {
set -e
get_cloudagent_bin

echo '[Unit]
Description=cloudagent

[Service]
Type=simple
ExecStart=/opt/bin/cloudagent
RemainAfterExit=no
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
' | $SUDO tee /etc/systemd/system/cloudagent.service
$SUDO systemctl enable cloudagent.service
set +e
}

install_gentoo() {
set -e
get_cloudagent_bin

echo '#!/sbin/runscript

command="/usr/bin/cloudagent"

start() {
        ebegin "Starting cloudagent"
        start-stop-daemon -b --start --exec "${command}"
        eend $?
}

' | $SUDO tee /etc/init.d/cloudagent
$SUDO chmod +x /etc/init.d/cloudagent
$SUDO rc-update add cloudagent
$SUDO rc-update -s
set +e
}

install_opensuse() {
set -e
get_cloudagent_bin

echo '#!/bin/bash
#
# cloudagent
#
# chkconfig: 35 11 88
# description: This starts cloudagent
#
# processname: /opt/bin/cloudagent
# config: /etc/sysconfig/cloudagent
# pidfile: /var/run/cloudagent.pid
#
# Return values according to LSB for all commands but status:
# 0 - success
# 1 - generic or unspecified error
# 2 - invalid or excess argument(s)
# 3 - unimplemented feature (e.g. "reload")
# 4 - insufficient privilege
# 5 - program is not installed
# 6 - program is not configured
# 7 - program is not running
#
### BEGIN INIT INFO
# Provides:       cloudagent
# Required-Start: $local_fs
# Required-Stop:  $local_fs
# Default-Start:  3 5
# Default-Stop:   0 1 2 6
# Short-Description: cloudagent
# Description:    cloudagent
### END INIT INFO

# First reset status of this service
. /etc/rc.status
rc_reset


PATH=/sbin:/bin:/usr/bin:/usr/sbin
prog="/opt/bin/cloudagent"

# Source function library.
. /lib/lsb/init-functions

# Allow anyone to run status
if [ "$1" = "status" ] ; then
        status $prog
        RETVAL=$?
        exit $RETVAL
fi

# Check that we are root ... so non-root users stop here
test $EUID = 0  ||  exit 4
PID="/var/run/cloudagent.pid"
CLOUDAGENT_OPTS=""

# Check config
test -f /etc/sysconfig/cloudagent && . /etc/sysconfig/cloudagent

RETVAL=0

start(){
        test -x /opt/bin/cloudagent || exit 5
        echo -n "Starting $prog: "
        startproc $prog "$CLOUDAGENT_OPTS"
        rc_status -v
}

stop(){
        echo -n "Stopping $prog: "
        killproc  -TERM $prog
        rc_status -v
}

restart(){
        stop
        start
}
status() {
    echo -n "Checking for $prog: "
    checkproc -p ${PID} $prog
    rc_status -v
}

# See how we were called.
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
esac

rc_exit
' | $SUDO tee /etc/init.d/cloudagent
$SUDO chmod +x /etc/init.d/cloudagent
$SUDO chkconfig cloudagent on
set +e
}

install_altlinux() {
set -e
get_cloudagent_bin

echo '#!/bin/sh
#
# cloudagent     This shell script takes care of starting and stopping
#                cloudagent.
#
# chkconfig: 2345 55 10
# description: cloudagent.

### BEGIN INIT INFO
# Provides:          cloudagent
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start cloudagent
# Description:       Enable cloudagent.
### END INIT INFO

WITHOUT_RC_COMPAT=1

# Source function library.
. /etc/init.d/functions
PROG=/opt/bin/cloudagent
PIDFILE=/var/run/cloudagent.pid
LOCKFILE=/var/lock/subsys/cloudagent
RETVAL=0

start()
{
        start_daemon --pidfile "$PIDFILE" --lockfile "$LOCKFILE" --expect-user root -- "$PROG"
        RETVAL=$?
        return $RETVAL
}

stop()
{
        stop_daemon --pidfile "$PIDFILE" --lockfile "$LOCKFILE" --expect-user root -- cloudagent
        RETVAL=$?
        return $RETVAL
}

restart()
{
        stop
        start
}

# See how we were called.
case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart|reload)
                restart
                ;;
        condstop)
                if [ -e "$LOCKFILE" ]; then
                        stop
                fi
                ;;
        condrestart)
                if [ -e "$LOCKFILE" ]; then
                        restart
                fi
                ;;
        status)
                status --expect-user root -- cloudagent
                RETVAL=$?
                ;;
        *)
                msg_usage "${0##*/} {start|stop|restart|condstop|condrestart|status}"
                RETVAL=1
esac

exit $RETVAL
' | $SUDO tee /etc/init.d/cloudagent
$SUDO chmod +x /etc/init.d/cloudagent
$SUDO chkconfig cloudagent on
set +e
}

install_cloudagent() {
  grep -qE "Arch Linux|Exherbo|openSUSE 12|openSUSE 13|Fedora 2|CentOS Linux 7|rhel|Debian GNU/Linux 8|Ubuntu 15.04|Ubuntu 15.10|Ubuntu 16.04|suse|SUSE" /etc/issue /etc/os-release 2>/dev/null && install_systemd
  grep -qE "Debian GNU/Linux 7|Debian GNU/Linux 6" /etc/issue /etc/os-release 2>/dev/null && install_debian
  grep -q "Gentoo" /etc/os-release && install_gentoo
  grep -qE "Ubuntu 14.04|Ubuntu 14.10|Ubuntu precise|Precise Pangolin|Ubuntu 10.04|Ubuntu 10.10|Ubuntu 11.04|Ubuntu 11.10|Ubuntu 12.04" /etc/issue /etc/os-release 2>/dev/null && install_upstart
  grep -qE "CentOS release 6.|CentOS release 5.|CentOS Linux release 6." /etc/issue /etc/os-release 2>/dev/null && install_centos
  grep -q "openSUSE 11." /etc/issue && install_opensuse
  #uname | grep -q FreeBSD && install_bsd
  grep -q "ALT Linux 6" /etc/altlinux-release && install_altlinux
}

get_cloudagent_bin() {
    $SUDO curl ${URL} --output ${BIN}
    $SUDO chmod +x ${BIN}
}

install_cloudagent

exit 0;
