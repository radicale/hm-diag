# Docker Container that runs the Nebra Diagnostics Tool

# FROM arm32v6/alpine:3.12.4
# FROM balenalib/raspberry-pi-debian:buster-build-20210705 as builder
# FROM balenalib/raspberry-pi-debian-python:buster-run-20210705 as runner
FROM balenalib/rockpi-4b-rk3399-debian-python as runner

WORKDIR /opt/

RUN \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" \
    TZ="$SYSTEM_TIMEZONE" \
    apt-get install -y \
        python3 \
        i2c-tools \
        usbutils \
        build-essential \
        python3-dev \
        libgirepository1.0-dev \
        libglib2.0-dev \
        dbus \
        libdbus-1-3 libdbus-glib-1-dev libgirepository1.0-dev libdbus-1-dev \
        python3-gi

# hadolint ignore=DL3018
# RUN apt install --no-cache \
#     python3=3.8.10-r0 \
#     i2c-tools=4.1-r3 \
#     usbutils=012-r1 \
#     build-base \
#     python3-dev \
#     glib-dev \
#     dbus-dev \
#     py3-pip=20.1.1-r0

RUN mkdir /tmp/build
COPY ./ /tmp/build
WORKDIR /tmp/build
RUN pip install --no-cache -r /tmp/build/requirements.txt
RUN python3 setup.py install
RUN rm -rf /tmp/build
COPY bin/gateway_mfr /usr/local/bin
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5000", "hw_diag:wsgi_app"]
