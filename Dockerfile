FROM i386/alpine:3.4

COPY pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl /pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl

RUN apk add --update \
    gcc \
    ffmpeg \
    nodejs \
    musl-dev \
    python \
    python-dev \
    py-pip \
    py-requests \
  && pip install /pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl pubnub pyserial \
  && apk del gcc musl-dev python-dev py-pip \
  && rm -rf /var/cache/apk/*

# Mavlink monitor
COPY ./mavlink_forwardpubnub.py /bin

# Use the mavlink tool
CMD mavlink_forwardpubnub.py; while true; do sleep 100; done
