FROM i386/debian:jessie

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    gcc \
    python \
    python-dev \
    python-pip \
    python-requests \
    python-serial \
  && pip install pymavlink pubnub \
  && apt-get purge -y gcc python-dev python-pip \
  && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/*

# Mavlink monitor
COPY ./mavlink_forwardpubnub.py /bin

# Use the mavlink tool
CMD mavlink_forwardpubnub.py; while true; do sleep 100; done
