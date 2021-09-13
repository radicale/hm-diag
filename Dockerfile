# Docker Container that runs the Nebra Diagnostics Tool

# FROM arm32v6/alpine:3.12.4
FROM balenalib/raspberry-pi-debian:buster-build-20210705 as builder
# FROM balenalib/raspberry-pi-debian-python:buster-run-20210705 as runner
# FROM balenalib/rockpi-4b-rk3399-debian-python:stretch as runner
# FROM balenalib/rockpi-4b-rk3399-debian:buster

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

RUN install_packages wget 
RUN echo "deb http://apt.radxa.com/buster-testing/ buster main" | tee -a /etc/apt/sources.list.d/apt-radxa-com.list 
RUN wget -O - apt.radxa.com/buster-testing/public.key | apt-key add - 
RUN apt-get update && apt-get install -y rockchip-overlay rockpi4-dtbo libmraa 
RUN apt-get install python3-pip python3-setuptools

RUN mkdir /tmp/build
COPY ./ /tmp/build
WORKDIR /tmp/build
RUN pip3 install --no-cache -r /tmp/build/requirements.txt
RUN python3 setup.py install
RUN rm -rf /tmp/build
COPY bin/gateway_mfr /usr/local/bin

RUN apt install git
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install cross
RUN git clone https://github.com/helium/gateway-mfr-rs
WORKDIR /tmp/build/gateway-mfr-rs
RUN rustup target add aarch64-unknown-linux-musl
RUN cross build --target aarch64-unknown-linux-musl --release

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5000", "hw_diag:wsgi_app"]
# To test:
# ./gateway-mfr-rs/target/aarch64-unknown-linux-musl/release/gateway_mfr --path /dev/i2c-7 test
