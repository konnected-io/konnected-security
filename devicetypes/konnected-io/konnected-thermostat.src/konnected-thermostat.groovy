/**
 *  Konnected Thermostat
 *
 *  Copyright 2018 konnected.io
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 *
 */

import groovy.transform.Field

// enummaps
@Field final Map      MODE = [
    OFF:   "off",
    HEAT:  "heat",
    COOL:  "cool",
    EHEAT: "emergency heat"
]

@Field final Map      FAN_MODE = [
    AUTO:      "auto",
    ON:        "on"
]

@Field final Map      OP_STATE = [
    COOLING:   "cooling",
    HEATING:   "heating",
    FAN:       "fan only",
    IDLE:      "idle"
]

@Field final Map SETPOINT_TYPE = [
    COOLING: "cooling",
    HEATING: "heating"
]

@Field final List HEAT_ONLY_MODES = [MODE.HEAT, MODE.EHEAT]
@Field final List COOL_ONLY_MODES = [MODE.COOL]
@Field final List RUNNING_OP_STATES = [OP_STATE.HEATING, OP_STATE.COOLING]
@Field final Integer  DEFAULT_HEATING_SETPOINT = 68
@Field final Integer  DEFAULT_COOLING_SETPOINT = 75

@Field List SUPPORTED_MODES = [MODE.OFF, MODE.HEAT, MODE.COOL, MODE.EHEAT]
@Field List SUPPORTED_FAN_MODES = [FAN_MODE.AUTO, FAN_MODE.ON]

metadata {
  definition (name: "Konnected Thermostat", namespace: "konnected-io", author: "konnected.io") {
        capability "Sensor"
        capability "Actuator"
        capability "Health Check"
        capability "Thermostat"
        capability "Relative Humidity Measurement"
        capability "Configuration"
        capability "Refresh"

        command "setTemperature", ["number"]
        command "setHumidity", ["number"]

        command "heatUp"
        command "heatDown"
        command "heatOn"
        command "coolUp"
        command "coolDown"
        command "coolOn"
        command "setpointUp"
        command "setpointDown"
        command "cycleMode"
        command "turnOff"

        tiles(scale: 2) {
            multiAttributeTile(name:"thermostatMulti", type:"thermostat", width:6, height:4) {
                tileAttribute("device.temperature", key: "PRIMARY_CONTROL") {
                    attributeState("default", label:'${currentValue}°F', unit:"°F", defaultState: true)
                }
                tileAttribute("device.temperature", key: "VALUE_CONTROL") {
                    attributeState("VALUE_UP", action: "setpointUp")
                    attributeState("VALUE_DOWN", action: "setpointDown")
                }
                tileAttribute("device.humidity", key: "SECONDARY_CONTROL") {
                    attributeState("default", label: '${currentValue}%', unit: "%", icon: "st.Weather.weather12", defaultState: true)
                }
                tileAttribute("device.thermostatOperatingState", key: "OPERATING_STATE") {
                    attributeState("idle", backgroundColor: "#c9c9c9")
                    attributeState("heating", backgroundColor: "#E86D13")
                    attributeState("cooling", backgroundColor: "#00A0DC")
                }
                tileAttribute("device.thermostatMode", key: "THERMOSTAT_MODE") {
                    attributeState("off",  label: '${name}')
                    attributeState("heat", label: '${name}')
                    attributeState("cool", label: '${name}')
                    attributeState("auto", label: '${name}')
                    attributeState("emergency heat", label: 'e-heat')
                }
                tileAttribute("device.heatingSetpoint", key: "HEATING_SETPOINT") {
                    attributeState("default", label: '${currentValue}', unit: "°F", defaultState: true)
                }
                tileAttribute("device.coolingSetpoint", key: "COOLING_SETPOINT") {
                    attributeState("default", label: '${currentValue}', unit: "°F",  defaultState: true)
                }
            }

			valueTile("currentMode", "device.thermostatMode", width: 2, height: 1, decoration: "flat") {
              state "off", label: "${name}", backgroundColor: "#CCCCCC", defaultState: true
              state "heat", label: "${name}", backgroundColor: "#E86D13"
              state "cool", label: "${name}", backgroundColor: "#00A0DC"
            }

            standardTile("mode", "device.thermostatMode", width: 2, height: 2, decoration: "flat") {
                state "off",            action: "cycleMode", nextState: "updating", icon: "st.thermostat.heating-cooling-off", backgroundColor: "#CCCCCC", defaultState: true
                state "heat",           action: "cycleMode", nextState: "updating", icon: "st.thermostat.heat"
                state "cool",           action: "cycleMode", nextState: "updating", icon: "st.thermostat.cool"
                state "emergency heat", action: "cycleMode", nextState: "updating", icon: "st.thermostat.emergency-heat"
                state "updating", label: "Working"
            }

            standardTile("fanMode", "device.thermostatFanMode", width: 1, height: 1, decoration: "flat") {
                state "auto",      action: "cycleFanMode", nextState: "updating", icon: "st.thermostat.fan-auto", defaultState: true
                state "on",        action: "cycleFanMode", nextState: "updating", icon: "st.thermostat.fan-on"
                state "updating", label: "Working"
            }

            standardTile("off", "device.thermostatMode", width: 1, height: 1, decoration: "flat") {
                state "off", action: "off", icon: "st.thermostat.heating-cooling-off"
            }

            valueTile("heatingSetpoint", "device.heatingSetpoint", width: 2, height: 2, decoration: "flat") {
                state "heat", action: "heat", label:'${currentValue}°F', unit: "°F", backgroundColor:"#E86D13"
            }
            standardTile("heatDown", "device.temperature", width: 1, height: 1, decoration: "flat") {
                state "default", label: "heat", action: "heatDown", icon: "st.thermostat.thermostat-down"
            }
            standardTile("heatUp", "device.temperature", width: 1, height: 1, decoration: "flat") {
                state "default", label: "heat", action: "heatUp", icon: "st.thermostat.thermostat-up"
            }

            valueTile("coolingSetpoint", "device.coolingSetpoint", width: 2, height: 2, decoration: "flat") {
                state "cool", action: "cool", label: '${currentValue}°F', unit: "°F", backgroundColor: "#00A0DC"
            }
            standardTile("coolDown", "device.temperature", width: 1, height: 1, decoration: "flat") {
                state "default", label: "cool", action: "coolDown", icon: "st.thermostat.thermostat-down"
            }
            standardTile("coolUp", "device.temperature", width: 1, height: 1, decoration: "flat") {
                state "default", label: "cool", action: "coolUp", icon: "st.thermostat.thermostat-up"
            }
      		standardTile("heatOn", "device.thermostatOperatingState", width: 2, height: 1, decoration: "flat") {
            	state "default", label: "heat on", action: "heatOn"
                state OP_STATE.HEATING, label: "heating", action: "heatOn", backgroundColor: "#E86D13"
            }
            standardTile("turnOff", "device.thermostatOperatingState", width: 2, height: 1, decoration: "flat") {
            	state "default", label: "turn off", action: "turnOff"
                state OP_STATE.IDLE, label: "off", action: "turnOff"
            }
			standardTile("coolOn", "device.thermostatOperatingState", width: 2, height: 1, decoration: "flat") {
            	state "default", label: "cool on", action: "coolOn"
                state OP_STATE.COOLING, label: "cooling", action: "coolOn", backgroundColor: "#00A0DC"
            }


            valueTile("roomTemp", "device.temperature", width: 2, height: 2, decoration: "flat") {
                state "default", label:'${currentValue} °F', unit: "°F", backgroundColors: [
                    // Celsius Color Range
                    [value:  0, color: "#153591"],
                    [value:  7, color: "#1E9CBB"],
                    [value: 15, color: "#90D2A7"],
                    [value: 23, color: "#44B621"],
                    [value: 29, color: "#F1D801"],
                    [value: 33, color: "#D04E00"],
                    [value: 36, color: "#BC2323"],
                    // Fahrenheit Color Range
                    [value: 40, color: "#153591"],
                    [value: 44, color: "#1E9CBB"],
                    [value: 59, color: "#90D2A7"],
                    [value: 74, color: "#44B621"],
                    [value: 84, color: "#F1D801"],
                    [value: 92, color: "#D04E00"],
                    [value: 96, color: "#BC2323"]
                ]
            }
		}

		main("roomTemp")
        details(["thermostatMulti",
            "heatDown", "heatUp",
            "mode",
            "coolDown", "coolUp",
            "heatingSetpoint",
            "coolingSetpoint",
            "fanMode", "off",
            "heatOn","turnOff","coolOn"
        ])

  }
}

def setTemperature(temp) {
  log.debug "New temperature is ${temp}"
  sendEvent(name:"temperature", value: temp, unit: "°F", displayed: false)
}

def setHumidity(pct) {
  log.debug "New humidity is ${pct}"
  sendEvent(name:"humidity", value: pct, unit: "%", displayed: false)
}


private String getThermostatMode() {
    return device.currentValue("thermostatMode") ?: DEFAULT_MODE
}

def setThermostatMode(String value) {
    log.trace "Executing 'setThermostatMode' $value"
    if (value in SUPPORTED_MODES) {
        sendEvent(name: "thermostatMode", value: value)
    } else {
        log.warn "'$value' is not a supported mode. Please set one of ${SUPPORTED_MODES.join(', ')}"
    }
}

def setThermostatFanMode(String value) {
    log.trace "Executing 'setThermostatFanMode' $value"
    if (value in SUPPORTED_FAN_MODES) {
        sendEvent(name: "thermostatFanMode", value: value)
    } else {
        log.warn "'$value' is not a supported mode. Please set one of ${SUPPORTED_FAN_MODES.join(', ')}"
    }
}

def cool() {
	setThermostatMode(MODE.COOL)
    setThermostatFanMode(FAN_MODE.AUTO)
}

def heat() {
	setThermostatMode(MODE.HEAT)
    setThermostatFanMode(FAN_MODE.AUTO)
}

def off() {
	setThermostatMode(MODE.OFF)
    setThermostatFanMode(FAN_MODE.AUTO)
}

def fanOn() {
	setThermostatFanMode(FAN_MODE.ON)
}

private coolOn() {
	log.trace "Executing 'coolOn'"
    parent.coolOn()
}

def updateOpState(newOpState) {
    log.debug "Updating thermostatOperatingState to '${newOpState}'"
    sendEvent(name: "thermostatOperatingState", value: newOpState)
}

private heatOn() {
	log.trace "Executing 'heatOn'"
    sendEvent(name: "thermostatOperatingState", value: OP_STATE.HEATING)
}
private turnOff() {
	log.trace "Executing 'turnOff'"
    parent.turnOff()
}


// setpoint
private Integer getThermostatSetpoint() {
    def ts = device.currentState("thermostatSetpoint")
    return ts ? ts.getIntegerValue() : DEFAULT_THERMOSTAT_SETPOINT
}

private Integer getHeatingSetpoint() {
    def hs = device.currentState("heatingSetpoint")
    return hs ? hs.getIntegerValue() : DEFAULT_HEATING_SETPOINT
}

def setHeatingSetpoint(Double degreesF) {
    log.trace "Executing 'setHeatingSetpoint' $degreesF"
    state.lastUserSetpointMode = SETPOINT_TYPE.HEATING
    sendEvent(name: "heatingSetpoint", value: degreesF, unit: "°F")
}

private heatUp() {
    log.trace "Executing 'heatUp'"
    def newHsp = getHeatingSetpoint() + 1
    setHeatingSetpoint(newHsp)
}

private heatDown() {
    log.trace "Executing 'heatDown'"
    def newHsp = getHeatingSetpoint() - 1
    setHeatingSetpoint(newHsp)
}

private Integer getCoolingSetpoint() {
    def cs = device.currentState("coolingSetpoint")
    return cs ? cs.getIntegerValue() : DEFAULT_COOLING_SETPOINT
}

def setCoolingSetpoint(Double degreesF) {
    log.trace "Executing 'setCoolingSetpoint' $degreesF"
    state.lastUserSetpointMode = SETPOINT_TYPE.COOLING
    sendEvent(name: "coolingSetpoint", value: degreesF, unit: "°F")
}

private coolUp() {
    log.trace "Executing 'coolUp'"
    def newCsp = getCoolingSetpoint() + 1
	setCoolingSetpoint(newCsp)
}

private coolDown() {
    log.trace "Executing 'coolDown'"
    def newCsp = getCoolingSetpoint() - 1
    setCoolingSetpoint(newCsp)
}

private setpointUp() {
    log.trace "Executing 'setpointUp'"
    String mode = getThermostatMode()
    if (mode in COOL_ONLY_MODES) {
        coolUp()
    } else if (mode in HEAT_ONLY_MODES) {
        heatUp()
    }
}

private setpointDown() {
    log.trace "Executing 'setpointDown'"
    String mode = getThermostatMode()
    if (mode in COOL_ONLY_MODES) {
        coolDown()
    } else if (mode in HEAT_ONLY_MODES) {
        heatDown()
    }
}
