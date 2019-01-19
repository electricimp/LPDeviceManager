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


// #require "ConnectionManager.lib.nut:3.1.0"
@include "github:electricimp/ConnectionManager/ConnectionManager.lib.nut@develop"

@include __PATH__  + "/../../LPDeviceManager.device.lib.nut"

cm <- ConnectionManager({
    "blinkupBehavior" : CM_BLINK_ALWAYS
})
// return;
lp <- LPDeviceManager(cm);


lp.onColdBoot(function() {
    cm.log("onColdBoot");
    imp.wakeup(5, function() {
        imp.reset();
    })
});

lp.onSwReset(function() {
    cm.log("onSwReset");
    imp.wakeup(5, function() {
        lp.doAndSleepFor(function() {
            cm.log("action...");
        }, 10);
    });
});

lp.onTimer(function() {
    cm.log("onTimer");
    lp.connect();
});

lp.onInterrupt(function() {
    cm.log("onInterrupt");
});

lp.onConnect(function() {
    cm.log("onConnect");
})

lp.onDisconnect(function(expected) {
    cm.log("onDisconnect: expected = " + expected);
})

