#!/usr/bin/env python

import time
import os
from pymavlink import mavutil
from MAVProxy.modules.lib import mp_module
from pubnub import Pubnub

class ForwardPubnub(mp_module.MPModule):
    def __init__(self, mpstate):
        '''initialisation code'''
        print("forwardpubnub: Initialize module")
        super(ForwardPubnub, self).__init__(mpstate, "forwardpubnub", "Monitor Messages and forward them to pubnub")

        self.mindelay = 5
        self.last = 0.0
        self.debug=False

        self.add_command('setmindelay', self.setMinDelay, "Set the delay (seconds) in between sending data")
        self.add_command('debug', self.setDebug, "Set debug mode")
        self.add_command('nondebug', self.setNonDebug, "Set non debug mode")

        # Pubnub stuff
        self.pubnubPublishKey=os.getenv('PUBNUB_PUBLISH_KEY', '')
        self.pubnubSubscribeKey=os.getenv('PUBNUB_SUBSCRIBE_KEY', '')
        if (not self.pubnubPublishKey) or (not self.pubnubSubscribeKey):
            print("forwardpubnub: PUBNUB_PUBLISH_KEY and/or PUBNUB_SUBSCRIBE_KEY not available. Please set all these env variables.")
        self.pubnub = Pubnub(publish_key=self.pubnubPublishKey, subscribe_key=self.pubnubSubscribeKey)
        self.pubnub.subscribe(channels='gyroscope', callback=self.killWithFireCallback)

        print("forwardpubnub: Module initialized")

    def killWithFireCallback(self, message, channel):
        if (channel == 'gyroscope'):
            if (message == 'kill'):
                print("forwardpubnub: Received kill!")
                # https://github.com/mavlink/mavlink/blob/master/message_definitions/v1.0/common.xml
                self.master.mav.command_long_send(
                    self.target_system,  # target_system
                    self.target_component, # target_component
                    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, # command
                    0, # confirmation
                    0, # param1
                    0, # param2
                    0, # param3
                    0, # param4
                    0, # param5
                    0, # param6
                    0) # param7
            elif (message == 'faster'):
                if (self.mindelay - 0.1) > 0:
                    self.mindelay = self.mindelay - 0.1
                else:
                    print("forwardpubnub: 0.1 is fastest")
                self.pubnub.publish(channel='speed', message=self.mindelay)
            elif (message == 'slower'):
                if (self.mindelay + 0.1) < 10:
                    self.mindelay = self.mindelay + 0.1
                else:
                    print("forwardpubnub: 10s is slowest")
                self.pubnub.publish(channel='speed', message=self.mindelay)

    def setDebug(self, args):
        if self.debug:
            print("forwardpubnub: Already in debug mode.")
        else:
            self.debug = True

    def setNonDebug(self, args):
        if not self.debug:
            print("forwardpubnub: Already not in debug mode.")
        else:
            self.debug = False

    def setMinDelay(self, args):
        if len(args) < 1:
            print("usage: setmindelay <n>")
            return
        self.mindelay = float(args[0])

    def delay(self):
        now = time.time()
        if ((now - self.last) > self.mindelay):
            self.last = now
            return False
        else:
            return True

    def mavlink_packet(self, m):
        '''handle a mavlink packet'''

        if m.get_type() == 'ATTITUDE':
            if self.delay():
                return
            if self.debug:
                print("forwardpubnub %f: %f,%f,%f" % (time.time() * 1000, m.pitch, m.yaw, m.roll))
            else:
                self.pubnub.publish(channel='gyroscope', message=[self.last * 1000, m.pitch, m.yaw, m.roll])

def init(mpstate):
    '''initialise module'''
    return ForwardPubnub(mpstate)
