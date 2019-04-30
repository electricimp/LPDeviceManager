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
 * The example implements sceleton of a Tracker application:
 *
 *
 * 1. Tracker in sleep:
 *  - No application or communication activity
 * 2. Wake for one of the following:
 *  - Check-In (periodic with configurable time period, i.e. 24 hours)
 *  2.1. Check-In Wake:
 *      - Tracker wakes upon expiration of time period
 *      - Determine temperature; if the temperature exceeds the predefined threshold value, creates an alert
 *      - Connect to cloud agent (i.e. power up modem and connect to cellular network)
 *      - Send sensor readings (temperature, humidity) to the cloud agent
 *      - Receive any pending data from cloud agent
 *      - Sleep, back to #2
 */

#require "HTS221.device.lib.nut:2.0.1"
#require "ConnectionManager.lib.nut:3.1.0"
#require "MessageManager.lib.nut:2.3.0"
#require "LPDeviceManager.device.lib.nut:0.1.0"

// Wake up period for the tracker to report data
const WAKE_UP_PERIOD_SEC        = 15;
const SEND_DATA_TIMEOUT_SEC     = 30;
const TEMP_HUM_SENSOR_I2C_ADDR  = 0xBE;

class TrackerApp {

    _lp         = null;
    _mm         = null;
    _debug      = null;
    _values     = null;
    _tempHumid  = null;

    constructor() {
        local cm = ConnectionManager({
            "blinkupBehavior" : CM_BLINK_ALWAYS
        })

        // 1. Setup low-power device management
        _lp = LPDeviceManager(cm);
        _lp.onConnect(function() {
            _log("onConnect occurred...");
            // Once connected, send readings and disconnect...
            _lp.doAsyncAndSleep(_sendReadings.bindenv(this), WAKE_UP_PERIOD_SEC, SEND_DATA_TIMEOUT_SEC);
        }.bindenv(this));

        _mm = MessageManager({
            "connectionManager": cm
        });
        _initHW();
    }

    function start() {
        _log("Starting app...");
        // 2. Read sensors
        _values = _readSensor();
        // 3. Get connected
        _lp.connect();
    }

    function _initHW() {
        _log("Init hardware...");
        local i2c = hardware.i2cKL;
        i2c.configure(CLOCK_SPEED_400_KHZ);
        _tempHumid = HTS221(i2c, TEMP_HUM_SENSOR_I2C_ADDR);
        _tempHumid.setMode(HTS221_MODE.ONE_SHOT);
    }

    function _sendReadings(done) {
        if ("temperature" in _values && "humidity" in _values) {
            _log("values: temp = " + _values.temperature + " humi = " + _values.humidity);
        } else {
            _err("Error reading the sensor...");
            return;
        }
        _mm.send("reading", _values, {
            "onReply" : function(msg, response) {
                done();
            }.bindenv(this)
        });
    }

    function _readSensor() {
        local result = _tempHumid.read();
        if ("error" in result) {
            _err("An Error Occurred: " + result.error);
            return;
        }
        return {
            "humidity" : result.humidity,
            "temperature" : result.temperature
        };
    }

    function _log(msg) {
        if (_lp.isConnected() && _debug) {
            server.log(msg);
        }
    }

    function _err(msg) {
        if (_lp.isConnected()) {
            server.error(msg);
        }
    }
}

app <- TrackerApp();
app.start();