# LPDeviceManager

The device-side library for low-power device and task management.

**To add this library to your project, add** `#require "LPDeviceManager.device.lib.nut:0.1.0"` **to the top of your agent code.**

**Note:** This is a beta release. Please file issues in [GitHub](https://github.com/electricimp/LPDeviceManager) to help us improve this library.

## Library Usage ##

Requirements: 
 1) The library can be instantiated only once, it should be treated as a singleton.
 2) Requires ConnectionManager v3.1.0 or above.
 3) `imp.onidle` should not be used along with the library (as there is a chance they will be overwritten)

### Constructor: LPDeviceManager(*cm[, wakeReasonCallbacks][, isDebug]*) ###

This method returns a new LPDeviceManager instance.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *cm* | String | Yes | An instance of ConnectionManager library v3.1.0 or above. |
| *wakeReasonCallbacks* | Table | No | A table of optional wake reasons callbacks. See [below](#wake-reason-callbacks). Default: an empty table. |
| *isDebug* | Boolean | No | Controls the debug output of the library. |

#### Wake Reason Callbacks ####

All keys are optional and values are callback functions.

| Key | Value | 
| --- | --- |
| *onColdBoot* | Callback to be executed on the cold boot, the callback takes no parameters | 
| *onSwReset* | Callback to be executed on a software reset, the callback takes no parameters |
| *onTimer* | Callback to be executed after "deep" sleep timer expires, the callback takes no parameters |
| *onInterrupt* | Callback to be triggered on a wakeup pin, the callback takes no parameters |
| *onPowerRestored* | Callback to be triggered when the imp's VBAT is powered during a cold start, the callback takes no parameters. Note: this wakereason is only available on impOS v40 and above |
| *defaultOnWake* | Callback that catches all other wake reasons, takes wake reason constant as a parameter [see the dev center for wake reason constant descriptions](https://developer.electricimp.com/api/hardware/wakereason) |

#### Example ####

```squirrel
// Wake up on timer flow
function onScheduledWake() {
    // Do something
}

// Wake up (not on timer) flow
function onBoot(wakereason) {
    server.log("Device Booted");
    // Do something
}

cm  <- ConnectionManager({ "blinkupBehavior": CM_BLINK_ALWAYS });
lpm <- LPDeviceManager(cm, {
    "onTimer"       : onScheduledWake.bindenv(this),
    "defaultOnWake" : onBoot.bindenv(this)
});
```

## Library Methods ##

### addOnIdle(*callback*) ###

The imp API [imp.onidle method](https://developer.electricimp.com/api/imp/onidle) should not be used along with this library. Use this method to add an action to imp.onidle method.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | Action to be triggered the next time the imp becomes idle. |

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

Synchronously executes the specified action and goes to deep sleep for the specified period of time.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | An action function to be fulfilled before we go to sleep. The function takes no arguments. |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the actions are all fulfilled. |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
const SLEEP_TIME    = 60;

function readTemp() {
    // Take an async temp reading
    th.setMode(HTS221_MODE.ONE_SHOT);
    local res = th.read(); 
    if ("error" in res) {
        // Log error
        server.error("Temperature/Humidity reading error: " + res.error);
    } else {
        // Log reading
        server.log("Temperature: " + res.temperature + "°C Humidity: " + res.humidity + "%");
    }
}

lpm.doAndSleep(readTemp.bindenv(this), SLEEP_TIME);
```

### doAsyncAndSleep(*action, sleepTime[, timeout]*) ### 

Asynchronously executes the specified action and goes to deep sleep for the specified period of time. If a timeout is specified the device will not wait for all actions to complete before going to sleep. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | An action function to be fulfilled before we go to sleep. The function takes no arguments. |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the actions are all fulfilled or timeout occurs. |
| *timeout* | Float | No | Time in seconds the device should wait for all actions to complete before giving up and going to sleep. |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
const MAX_WAKE_TIME = 30;
const SLEEP_TIME    = 60;

function readTemp(done) {
    // Take an async temp reading
    th.setMode(HTS221_MODE.ONE_SHOT);
    th.read(function(res) {
        if ("error" in res) {
            // Log error
            server.error("Temperature/Humidity reading error: " + res.error);
        } else {
            // Log reading
            server.log("Temperature: " + res.temperature + "°C Humidity: " + res.humidity + "%");
            // Go to sleep
            done();
        }
    }.bindenv(this))
}

lpm.doAsyncAndSleep(readTemp.bindenv(this), SLEEP_TIME, MAX_WAKE_TIME);
```

### sleepFor(*sleepTime*) ### 

Puts the device to sleep for the specified period of time, as soon as it becomes idle.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for. |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Put the device to sleep for 60 seconds
lpm.sleepFor(60);
```

### connect() ### 

Attempts to establish a connection between the imp and the server. This is the same as calling ConnectionManager's connect method.

#### Parameters ####

None.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Connect to the server
lpm.connect();
```

### disconnect() ### 

Disconnects the imp from the server and turns the radio off. This is the same as calling ConnectionManager's disconnect method with the force parameter set to `true`.

#### Parameters ####

None.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Disconnect from the server
lpm.disconnect();
```

### onConnect(*callback[, callbackName]*) ### 

Registers a callback to be executed on successful connection to the server.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when device is connected. This function has no parameters. |
| *callbackName* | String | No | An optional callback name that can be used to register multiple callbacks. |

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

Registers a callback to be executed when the device disconnects or an error occurs during a connection attempt.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when device is disconnected. This function has one parameter, a boolean, `true` if the disconnect was triggered programmatically. |
| *callbackName* | String | No | An optional callback name that can be used to register multiple callbacks. |

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

Returns the device's connectivity status. This is the same as calling Connection Manager's isConnected method.

#### Parameters ####

None.

#### Return Value ####

Boolean, `true` if the device is connected and `false` otherwise.

#### Example ####

```squirrel
if (lpm.isConnected()) server.log("Device is connected");
```

### wakeReasonDesc() ### 

Returns a string description of the wake up reason.

#### Parameters ####

None.

#### Return Value ####

String, description of the wake up reason.

#### Example ####

```squirrel
server.log("Wake reason: " + lpm.wakeReasonDesc());
```

## Full Example ##

Device Code: 
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

cm <- ConnectionManager({ "blinkupBehavior": CM_BLINK_ALWAYS });
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

Agent Code: 
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

### Links to more examples ###

- [Library Usage Examples](./examples)
- [Cellular Asset Tracker Example](https://github.com/electricimp/CellularAssetTrackerExample)

## License ##

This library is licensed under the [MIT License](./LICENSE).