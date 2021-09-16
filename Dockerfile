# Docker Container that runs the Nebra Diagnostics Tool

FROM balenalib/raspberry-pi-debian:buster-build-20210705 as builder

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

RUN apt-get install python3-pip python3-setuptools
RUN mkdir /tmp/build
COPY ./ /tmp/build
WORKDIR /tmp/build
RUN pip3 install --no-cache -r /tmp/build/requirements.txt
RUN python3 setup.py install
RUN rm -rf /tmp/build
COPY bin/gateway_mfr /usr/local/bin
COPY finish_setup_and_start_gunicorn finish_setup_and_start_gunicorn

RUN apt-get install wget
RUN echo "deb http://apt.radxa.com/buster-stable/ buster main" | tee -a /etc/apt/sources.list.d/apt-radxa-com.list
RUN wget -O - apt.radxa.com/buster-stable/public.key | apt-key add -
RUN apt-get update && apt-get install -y rockchip-overlay rockpi4-dtbo

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5000", "hw_diag:wsgi_app"]
# ENTRYPOINT ["finish_setup_and_start_gunicorn"]
