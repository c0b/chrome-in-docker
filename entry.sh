#!/bin/bash

set -xe

VNC_STORE_PWD_FILE=~/.vnc/passwd
if [ ! -e "${VNC_STORE_PWD_FILE}" -o -n "${VNC_PASSWORD}" ]; then
    mkdir -vp ~/.vnc

    # the default VNC password is 'hola'
    x11vnc -storepasswd ${VNC_PASSWORD:-hola} ${VNC_STORE_PWD_FILE}
fi

# default CHROME is the stable version
export CHROME=${CHROME:-/opt/google/chrome/google-chrome}

# make the new volume owned by regular user
sudo chown -Rv 1000:100 /tmp/chrome-data

# retain running as pid 1
exec supervisord