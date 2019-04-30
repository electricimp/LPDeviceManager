# LPDeviceManager

The device-side library for low-power device and task management

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
| *wakeReasonCallbacks* | Table | No | A table of optional wake reasons callbacks. See below. Default is an empty table. |
| *isDebug* | Boolean | No | Controls the debug output of the library. |

##### Wake Reason Callbacks #####

All keys are optional and values are callback functions.

| Key | Value | 
| --- | --- |
| onColdBoot | Callback to be executed on the cold boot, the callback takes no parameters | 
| onSwReset | Callback to be executed on a software reset, the callback takes no parameters |
| onTimer | Callback to be executed after "deep" sleep time expired, the callback takes no parameters |
| onInterrupt | Callback to be triggered on a wakeup pin, the callback takes no parameters |
| onPowerRestored | Callback to be triggered when the imp is VBAT powered during a cold start, the callback takes no parameters |
| defaultOnWake | Callback that catches all other wake reasons, takes wake reason constant as a parameter [see docs for constant description](https://developer.electricimp.com/api/hardware/wakereason) |

## Library Methods ##

### addOnIdle(*callback*) ###

The imp API [imp.onidle method](https://developer.electricimp.com/api/imp/onidle) should not be used along with this library. Use this method to add an action to imp.onidle method.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | Action to be triggered the next time the imp becomes idle. |

#### Return Value ####

Nothing.

### doAndSleep(*action, sleepTime*) ### 

Synchronously executes the specified action(s) and goes to deep sleep for the specified period of time.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | An action function to be fulfilled before we go to sleep. The function takes no arguments. |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the actions are all fulfilled. |

#### Return Value ####

Nothing.

### doAsyncAndSleep(*action, sleepTime[, timeout]*) ### 

Asynchronously executes the specified action(s) and goes to deep sleep for the specified period of time. If a timeout is specified the device will not wait for all actions to complete before going to sleep. 

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *action* | Function | Yes | An action function to be fulfilled before we go to sleep. The function takes no arguments. |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for after the actions are all fulfilled or timeout occurs. |
| *timeout* | Float | No | Time in seconds the device should wait for all actions to complete before giving up and going to sleep. |

#### Return Value ####

Nothing.

### sleepFor(*sleepTime*) ### 

Puts the device to sleep for the specified period of time, as soon as it becomes idle.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *sleepTime* | Float | Yes | Time in seconds the device should sleep for. |

#### Return Value ####

Nothing.

### connect() ### 

Attempts to establish a connection between the imp and the server.

#### Parameters ####

None.

#### Return Value ####

Nothing.

### disconnect() ### 

Disconnects the imp from the server and turns the radio off.

#### Parameters ####

None.

#### Return Value ####

Nothing.

### onConnect(*callback[, callbackName]*) ### 

Registers a callback to be executed on successful connection to the server.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when device is connected. This function has no parameters. |
| *callbackName* | String | No | An optional callback name that can be used to register multiple callbacks. |

#### Return Value ####

Nothing.

### onDisconnect(*callback[, callbackName]*) ### 

Registers a callback to be executed when the device disconnects or an error occurs during a connection attempt.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | A function to be called when device is disconnected. This function has one parameter, a boolean, `true` if the disconnect was triggered programmatically. |
| *callbackName* | String | No | An optional callback name that can be used to register multiple callbacks. |

#### Return Value ####

Nothing.

### isConnected() ### 

Returns the device's connectivity status.

#### Parameters ####

None.

#### Return Value ####

Boolean, `true` if the device is connected and `false` otherwise.

### wakeReasonDesc() ### 

Returns a string description of the wake up reason.

#### Parameters ####

None.

#### Return Value ####

String, description of the wake up reason.
