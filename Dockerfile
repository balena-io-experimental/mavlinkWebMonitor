FROM i386/alpine:3.4

COPY pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl /pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl

COPY webserver/package.json /usr/src/dronegraph/package.json

WORKDIR /usr/src/dronegraph

RUN apk add --update \
    gcc \
    ffmpeg \
    nodejs \
    make \
    musl-dev \
    python \
    python-dev \
    py-pip \
    py-requests \
  && pip install /pymavlink-2.0.3-cp27-cp27mu-linux_i686.whl pubnub pyserial \
  && JOBS=MAX npm install --production --unsafe-perms \
  && apk del gcc make musl-dev python-dev py-pip \
  && rm -rf /var/cache/apk/*

COPY webserver/ /usr/src/dronegraph

# Mavlink monitor
COPY ./mavlink_forwardpubnub.py /bin

# Use the mavlink tool
CMD mavlink_forwardpubnub.py &; node index.js; while true; do sleep 100; done
