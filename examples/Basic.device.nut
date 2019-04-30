// MIT License
//
// Copyright 2019 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

/**
 * This examples shows some basic low-power device manager functionality.
 * The implemented scenario is the following:
 * - on cold boot, software reset is scheduled after 5 seconds
 * - on sowftware reset a simple function performing a log operation followed by 10 second sleep is scheduled
 * - connect and disconnect events are logged
 */

#require "ConnectionManager.lib.nut:3.1.0"
#require "LPDeviceManager.device.lib.nut:0.1.0"

function defaultOnWake(reason) {
    cm.log("defaultOnWake");
    imp.wakeup(5, function() {
        imp.reset();
    })
}

function onSwReset() {
    cm.log("onSwReset");
    imp.wakeup(5, function() {
        lp.doAsyncAndSleep(function(done) {
            cm.log("action...");
            done();
        }, 10);
    });
}

function onTimer() {
    cm.log("onTimer");
    lp.connect();
}

function onInterrupt() {
    cm.log("onInterrupt");
}

cm <- ConnectionManager({
    "blinkupBehavior" : CM_BLINK_ALWAYS
})
// return;
lp <- LPDeviceManager(cm, {
    "defaultOnWake" : defaultOnWake,
    "onSwReset"     : onSwReset,
    "onTimer"       : onTimer,
    "onInterrupt"   : onInterrupt
}, true);

lp.onConnect(function() {
    cm.log("onConnect");
    cm.log("DONE");
})

lp.onDisconnect(function(expected) {
    cm.log("onDisconnect: expected = " + expected);
})
