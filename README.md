# LPDeviceManager #

This is a library designed to help you manage low-power devices and the tasks they need to perform.

**To include this library in your project, add** `#require "LPDeviceManager.device.lib.nut:0.1.0"` **at the top of your agent code.**

**Note** This is a beta release. Please file issues in [GitHub](https://github.com/electricimp/LPDeviceManager) to help us improve this library.

## Library Usage ##

The LPDeviceManager library has the following requirements:

 1. The library’s primary class must only be instantiated once, so it should be treated as a singleton.
 2. The library depends upon [ConnectionManager](https://github.com/electricimp/ConnectionManager) 3.1.0 or above, so make sure you `#require` this library too. The [full example, below](#full-example) shows how the two libraries are used together.
 3. The imp API method [**imp.onidle()**](https://developer.electricimp.com/api/imp/onidle) should **not** be used along with the library as there is a chance the library will override your idle code with its own. See the [*addOnIdle()*](#addonidlecallback) method, below, for further information.

### Constructor: LPDeviceManager(*cm[, wakeReasonCallbacks][, isDebug]*) ###

This method returns a new LPDeviceManager instance.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *cm* | Object | Yes | An instance of [ConnectionManager](https://github.com/electricimp/ConnectionManager) 3.1.0 or above |
| *wakeReasonCallbacks* | Table | No | A table of optional [wake reason callbacks](#wake-reason-callbacks). Default: an empty table |
| *isDebug* | Boolean | No | Controls the debug output of the library. Set to `true` for extra output. Default: `false` |

#### Wake Reason Callbacks ####

LPDeviceManager allows you to set code to be executed when the device wakes for a specific reason.

All of the following keys are optional. Their values are callback functions that will be triggered in the event of the wake reasons for which the keys are named.

| Key | Value |
| --- | --- |
| *onColdBoot* | Callback to be executed on a cold boot. The callback takes no parameters |
| *onSwReset* | Callback to be executed on a software reset. The callback takes no parameters |
| *onTimer* | Callback to be executed after a deep sleep timer fires. The callback takes no parameters |
| *onInterrupt* | Callback to be triggered when a wakeup pin is asserted. The callback takes no parameters |
| *onPowerRestored* | Callback to be triggered when the imp's V<sub>BAT</sub> is powered during a cold start. The callback takes no parameters. **Note** This wake reason is only available on impOS™ 40 and above |
| *defaultOnWake* | Callback that catches [all other wake reasons](https://developer.electricimp.com/api/hardware/wakereason), and takes the impOS wake reason constant as its argument |

#### Example ####

```squirrel
// Wake up on timer flow
function onScheduledWake() {
    server.log("Device woke according to schedule");
    // Do something
}

// Wake up (not on timer) flow
function onBoot(wakereason) {
    server.log("Device booted");
    // Do something
}

local cm = ConnectionManager({"blinkupBehavior": CM_BLINK_ALWAYS});
local lpm = LPDeviceManager(cm, {"onTimer"       : onScheduledWake.bindenv(this),
                                 "defaultOnWake" : onBoot.bindenv(this)});
```

## Library Methods ##

### addOnIdle(*callback*) ###

The imp API method [**imp.onidle()**](https://developer.electricimp.com/api/imp/onidle) should not be used when you are using the LPDeviceManager library. Instead, use this method to add an action that will be performed when the imp goes idle.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | Action to be triggered the next time the imp becomes idle |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
function onIdleTask() {
    server.log("Device is idle");
}

lpm.addOnIdle(onIdleTask.bindenv(this));
```

### doAndSleep(*action, sleepTime*) ###

This method synchronously executes the specified action and then puts the imp into deep sleep for the specified period of time.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | A function to be called before the imp sleeps. The function has no parameters |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the action is all fulfilled |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
const SLEEP_TIME = 60;

function readTemp() {
    // Take a synchronous sensor reading
    sensor.setMode(HTS221_MODE.ONE_SHOT);
    local reading = sensor.read();
    if ("error" in reading) {
        // Log error
        server.error("Temperature/Humidity reading error: " + reading.error);
    } else {
        // Log reading
        server.log("Temperature: " + reading.temperature + "°C Humidity: " + reading.humidity + "%");
    }
}

lpm.doAndSleep(readTemp.bindenv(this), SLEEP_TIME);
```

### doAsyncAndSleep(*action, sleepTime[, timeout]*) ###

This method asynchronously executes the specified action and then puts the imp into deep sleep for the specified period of time. If a timeout is specified, the device will not wait for the action to complete before going to sleep.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | A function to be called before the imp sleeps. The function has no parameters |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the action is fulfilled or timeout occurs |
| *timeout* | Float | No | Time in seconds the device should wait for the action to complete before sleeping anyway |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
const MAX_WAKE_TIME = 30;
const SLEEP_TIME    = 60;

function readTemp() {
    // Take an asynchronous sensor reading
    sensor.setMode(HTS221_MODE.ONE_SHOT);
    sensor.read(function(reading) {
        if ("error" in reading) {
            // Log error
            server.error("Temperature/Humidity reading error: " + reading.error);
        } else {
            // Log reading
            server.log("Temperature: " + reading.temperature + "°C Humidity: " + reading.humidity + "%");
        }
    }.bindenv(this))
}

lpm.doAsyncAndSleep(readTemp.bindenv(this), SLEEP_TIME, MAX_WAKE_TIME);
```

### sleepFor(*sleepTime*) ###

This method puts the device to sleep for the specified period of time, as soon as it becomes idle.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Put the device to sleep for 60 seconds
lpm.sleepFor(60);
```

### connect() ###

This method attempts to establish a connection between the imp module and the impCloud™ server. It is equivalent to calling ConnectionManager’s *connect()* method.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Connect to the server
lpm.connect();
```

### disconnect() ###

This method disconnects the imp from the impCloud server and, if in use, powers down the radio. It is equivalent to calling ConnectionManager’s *disconnect()* method with the *force* parameter passed `true`.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Disconnect from the server
lpm.disconnect();
```

### onConnect(*callback[, callbackName]*) ###

This method registers a function that will be called when the imp successfully connects to the impCloud server.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when device has connected. This function has no parameters |
| *callbackName* | String | No | An optional identifier that can be used to register multiple callbacks |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Register a connection handler
lpm.onConnect(function() {
    server.log("Connected");
});
```

### onDisconnect(*callback[, callbackName]*) ###

This method registers a function that will be called when the imp disconnects from the impCloud server, or an error occurs during an attempt to connect to the server.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when the device has disconnected. This function has one parameter, a boolean, which is passed `true` if the disconnect was triggered programmatically, otherwise `false` |
| *callbackName* | String | No | An optional identifier that can be used to register multiple callbacks  |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Register a disconnect handler
lpm.onDisconnect(function(expected) {
    if (expected) {
        lpm.sleepFor(60);
    } else {
        lpm.connect();
    }
});
```

### isConnected() ###

This method indicates whether the is connected or not. This is equivalent to calling Connection Manager’s *isConnected()* method.

#### Return Value ####

Boolean &mdash; `true` if the device is connected, otherwise `false`.

#### Example ####

```squirrel
server.log("Device is " + (lpm.isConnected() ? "connected" : "disconnected"));
```

### wakeReasonDesc() ###

This method returns a human-readable string description of the imp’s most recent wake reason.

#### Return Value ####

String &mdash; a description of the wake reason.

#### Example ####

```squirrel
server.log("Wake reason: " + lpm.wakeReasonDesc());
```

## Full Example ##

### Device Code ###

```squirrel
// Device Code
#require "ConnectionManager.lib.nut:3.1.1"
#require "HTS221.device.lib.nut:2.0.1"
#require "LPDeviceManager.device.lib.nut:0.1.0"

const MAX_WAKE_TIME = 30;
const SLEEP_TIME    = 60;
const MAX_TEMP      = 20;

// Explorer Kit, sensor i2c
local SENSOR_I2C = hardware.i2c89;
SENSOR_I2C.configure(CLOCK_SPEED_400_KHZ);

cm <- ConnectionManager({"blinkupBehavior": CM_BLINK_ALWAYS});
th <- HTS221(SENSOR_I2C);
lpm <- null;

// Take a async temperature reading then go to sleep
function takeReading(done) {
    th.setMode(HTS221_MODE.ONE_SHOT);
    th.read(function(res) {
        if ("error" in res) {
            // Didn't get a successful reading, go to sleep
            done();
        } else {
            // Report temperature above 20°C
            if (res.temperature > MAX_TEMP) {
                lpm.onConnect(function() {
                    server.log("Wake reason: " + lpm.wakeReasonDesc());
                    // Log reading
                    server.log("Temperature: " + res.temperature + "°C Humidity: " + res.humidity + "%");
                    // Send reading to agent
                    agent.send("reading", res);
                    done();
                }.bindenv(this))
                lpm.connect();
            } else {
                // Temp was in range, go to sleep
                done();
            }
        }
    }.bindenv(this))
}

// Wake up on timer flow
function onScheduledWake() {
    // Set a limit on how long we are connected
    // Note: Setting a fixed duration to sleep here means next connection
    // will happen in calculated time + the time it takes to complete all
    // tasks.
    lpm.doAsyncAndSleep(takeReading.bindenv(this), SLEEP_TIME, MAX_WAKE_TIME);
}

// Wake up (not on timer) flow
function onBoot(wakereason) {
    server.log("Wake reason: " + lpm.wakeReasonDesc());

    // Set a limit on how long we are connected
    // Note: Setting a fixed duration to sleep here means next connection
    // will happen in calculated time + the time it takes to complete all
    // tasks.
    lpm.doAsyncAndSleep(function(done) {
        agent.on("restartACK", function(notUsed) {
            done();
        }.bindenv(this))
        agent.send("restart", "Device restarted with wakereason: " + wakereason);
    }.bindenv(this), SLEEP_TIME, MAX_WAKE_TIME);
}

handlers <- {
    "onTimer"       : onScheduledWake.bindenv(this),
    "defaultOnWake" : onBoot.bindenv(this)
}

lpm = LPDeviceManager(cm, handlers);
```

### Agent Code ###

```squirrel
// Agent Code
device.on("restart", function(msg) {
    server.log(msg);
    device.send("restartACK", null);
}.bindenv(this))

device.on("reading", function(msg) {
    server.log(http.jsonencode(msg));
}.bindenv(this))
```

### Further Examples ###

Electric Imp’s GitHub repository contains further examples you can try out.

- [Library Usage Examples](./examples)
- [Cellular Asset Tracker Example](https://github.com/electricimp/CellularAssetTrackerExample)

## License ##

This library is licensed under the [MIT License](./LICENSE).