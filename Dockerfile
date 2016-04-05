FROM resin/edison-python:2.7

RUN apt-get update && apt-get install python-dev gcc python-numpy && rm -rf /var/lib/apt/lists/*

RUN pip install mavproxy pubnub

# Install the mavlink module
COPY ./mavproxy_forwardpubnub.py /usr/local/lib/python2.7/site-packages/MAVProxy/modules

# Autoload the mavlink module
COPY ./mavinit.scr /root/.mavinit.scr

CMD /bin/sh -c 'mavproxy.py --master=/dev/ttyMFD1 --baudrate=921600 --logfile=/dev/null --daemon; sleep 999999;'
