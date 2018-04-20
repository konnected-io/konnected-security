/**
 *  Konnected
 *
 *  Copyright 2018 konnected.io
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 *
 */
import groovy.time.TimeCategory

definition(
  name:        "Konnected Thermostat",
  parent:      "konnected-io:Konnected (Connect)",
  namespace:   "konnected-io",
  author:      "konnected.io",
  description: "Konnected devices bridge wired things with SmartThings",
  category:    "My Apps",
  iconUrl:     "https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/KonnectedSecurity.png",
  iconX2Url:   "https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/KonnectedSecurity@2x.png",
  iconX3Url:   "https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/KonnectedSecurity@3x.png",
  singleInstance: true
)

mappings {
  path("/ping") { action: [ GET: "devicePing"] }
}

preferences {
  page(name: "pageWelcome",       install: false, uninstall: true, content: "pageWelcome", nextPage: "pageConfiguration")
  page(name: "pageDiscovery",     install: false, content: "pageDiscovery" )
  page(name: "pageConfiguration", install: true, content: "pageConfiguration")
}

def installed() {
  log.info "installed(): Installing Konnected Device: " + state.device?.mac
  initialize()
}

def updated() {
  log.info "updated(): Updating Konnected Device: " + state.device?.mac
  unsubscribe()
  unschedule()
  initialize()

  def thermostat = getThermostat()
  subscribe(temperatureSensors, "temperature", temperatureHandler)
  subscribe(humiditySensors, "humidity", humidityHandler)
  subscribe(contactSensors, "contact", openCloseHandler)
  subscribe(thermostat, "heatingSetpoint", evaluateConditions)
  subscribe(thermostat, "coolingSetpoint", evaluateConditions)
  subscribe(thermostat, "thermostatMode", evaluateConditions)
  subscribe(location, "mode", evaluateConditions, [filterEvents: true])
  thermostat.setTemperature(calculateCurrentTemperature())
  thermostat.setHumidity(calculateCurrentHumidity())
}

def uninstalled() {
  def device = state.device
  log.info "uninstall(): Removing Konnected Device $device?.mac"
  revokeAccessToken()

  def body = [
    token : "",
    apiUrl : "",
    sensors : [],
    actuators : []
  ]

  if (device) {
    parent.removeKnownDevice(device.mac)
    sendHubCommand(new physicalgraph.device.HubAction([
      method: "PUT",
      path: "/settings",
      headers: [ HOST: getDeviceIpAndPort(device), "Content-Type": "application/json" ],
      body : groovy.json.JsonOutput.toJson(body)
    ], getDeviceIpAndPort(device) ))
  }
}

def initialize() {
  discoverySubscription()
  if (app.label != deviceName()) { app.updateLabel(deviceName()) }
  parent.registerKnownDevice(state.device.mac)
  childDeviceConfiguration()
  updateSettingsOnDevice()
}

def getThermostat() {
	return getChildDevice(state.device.mac)
}

def deviceName() {
  if (name) {
    return name
  } else if (state.device) {
    return "konnected-" + state.device.mac[-6..-1]
  } else {
    return "New Konnected device"
  }
}

// Page : 1 : Welcome page - Manuals & links to devices
def pageWelcome() {
  def device = state.device
  dynamicPage( name: "pageWelcome", title: deviceName(), nextPage: "pageConfiguration") {
    section() {
      if (device) {
        href(
          name:        "device_" + device.mac,
          image:       "https://docs.konnected.io/assets/favicons/apple-touch-icon.png",
          title:       "Device status",
          url:         "http://" + getDeviceIpAndPort(device)
        )
      } else {
        href(
          name:        "discovery",
          title:       "Tap here to start discovery",
          page:        "pageDiscovery"
        )
      }
    }

    section("Help & Support") {
      href(
        name:        "pageWelcomeManual",
        title:       "Instructions & Documentation",
        description: "Tap to view the online documentation at http://docs.konnected.io",
        required:    false,
        image:       "https://raw.githubusercontent.com/konnected-io/docs/master/assets/images/manual-icon.png",
        url:         "http://docs.konnected.io/security-alarm-system/"
      )
    }
  }
}

// Page : 2 : Discovery page
def pageDiscovery() {
  if(!state.accessToken) { createAccessToken() }

  // begin discovery protocol if device has not been found yet
  if (!state.device) {
    discoverySubscription()
    parent.discoverySearch()
  }

  dynamicPage(name: "pageDiscovery", install: false, refreshInterval: 3) {
    if (state.device?.verified) {
      section() {
        href(
          name: "discoveryComplete",
          title: "Found konnected-" + state.device.mac[-6..-1] + "!",
          description: "Tap to continue",
          page: "pageConfiguration"
        )
      }
    } else {
      section("Please wait while we discover your device") {
        paragraph "This may take up to a minute."
      }
    }
  }
}

// Page : 3 : Configure things wired to the Konnected board
def pageConfiguration(params) {
  def device = state.device
  dynamicPage(name: "pageConfiguration") {
    section() {
      input(
        name: "name",
        type: "text",
        title: "Device name",
        required: false,
        defaultValue: "konnected-" + device?.mac[-6..-1]
      )
    }
    section("Temperature input(s)"){
		input "temperatureSensors", "capability.temperatureMeasurement", title: "Temperature sensor(s)", multiple: true
        input "temperatureCalc", "enum", title: "When multiple are selected, use", options: ["Average","Minimum","Maximum","Median"], defaultValue: "Average", required: false
	}
    section("Humidity input(s)"){
		input "humiditySensors", "capability.relativeHumidityMeasurement", title: "Humidity sensor(s)", multiple: true, required: false
        input "humidityCalc", "enum", title: "When multiple are selected, use", options: ["Average","Minimum","Maximum","Median"], defaultValue: "Average", required: false
	}
    section("Disable heating and cooling in these modes"){
    	input "energySavingModes", "mode", title: "Select mode(s)", multiple: true, required: false
    }
    section("Disable heating and cooling when doors/windows are open"){
        input "contactSensors", "capability.contactSensor", title: "Open/close sensor(s)", multiple: true, required: false
        input "openContactTime", "number", title: "For how many minutes?", required: false, defaultValue: 5
    }
  }
}

def getDeviceIpAndPort(device) {
  "${convertHexToIP(device.networkAddress)}:${convertHexToInt(device.deviceAddress)}"
}

// Device Discovery : Subscribe to SSDP events
def discoverySubscription() {
  subscribe(location, "ssdpTerm.${parent.discoveryDeviceType()}", discoverySearchHandler, [filterEvents:false])
}

// Device Discovery : Handle search response
def discoverySearchHandler(evt) {
  def event = parseLanMessage(evt.description)
  event << ["hub":evt?.hubId]
  String ssdpUSN = event.ssdpUSN.toString()
  def device = state.device
  if (device?.ssdpUSN == ssdpUSN) {
    device.networkAddress = event.networkAddress
    device.deviceAddress = event.deviceAddress
    log.debug "Refreshed attributes of device $device"
  } else if (device == null && parent.isNewDevice(event.mac)) {
    state.device = event
    log.debug "Discovered new device $event"
    unsubscribe()
    discoveryVerify(event)
  }
}

// Device Discovery : Verify a Device
def discoveryVerify(Map device) {
  log.debug "Verifying communication with device $device"
  String host = getDeviceIpAndPort(device)
  sendHubCommand(
    new physicalgraph.device.HubAction(
      """GET ${device.ssdpPath} HTTP/1.1\r\nHOST: ${host}\r\n\r\n""",
      physicalgraph.device.Protocol.LAN,
      host,
      [callback: discoveryVerificationHandler]
    )
  )
}

//Device Discovery : Handle verification response
def discoveryVerificationHandler(physicalgraph.device.HubResponse hubResponse) {
  def body = hubResponse.xml
  def device = state.device
  if (device?.ssdpUSN.contains(body?.device?.UDN?.text())) {
    log.debug "Verification Success: $body"
    device.name =  body?.device?.roomName?.text()
    device.model = body?.device?.modelName?.text()
    device.serialNumber = body?.device?.serialNum?.text()
    device.verified = true
  }
}

// Child Devices : create/delete child devices from SmartThings app selection
def childDeviceConfiguration() {
  def device = state.device
  def deviceDNI = device.mac
  def deviceChild = getChildDevice(deviceDNI)

  if (!deviceChild) {
  	addChildDevice("konnected-io", "Konnected Thermostat", deviceDNI, device.hub, [ "label": "Konnected Thermostat", "completedSetup": true ])
  }
}

//Device: Ping from device
def devicePing() {
  return ""
}

//Device : update NodeMCU with token, url, sensors, actuators from SmartThings
def updateSettingsOnDevice() {
  if(!state.accessToken) { createAccessToken() }

  def device    = state.device
  def sensors   = []
  def actuators = [[pin: 1, trigger: 0]]
  def ip        = getDeviceIpAndPort(device)
  def mac       = device.mac

  def body = [
    token : state.accessToken,
    apiUrl : apiServerUrl + "/api/smartapps/installations/" + app.id,
    sensors : sensors,
    actuators : actuators
  ]

  log.debug "Updating settings on device $mac at $ip"
  sendHubCommand(new physicalgraph.device.HubAction([
    method: "PUT",
    path: "/settings",
    headers: [ HOST: ip, "Content-Type": "application/json" ],
    body : groovy.json.JsonOutput.toJson(body)
  ], ip ))
}

def coolOn() {
  def device = state.device
  log.debug "Updating Konnected Thermostat " + getDeviceIpAndPort(device) + "/device/1 to ON"
  sendHubCommand(new physicalgraph.device.HubAction([
    method: "PUT",
    path: "/device",
    headers: [ HOST: getDeviceIpAndPort(device), "Content-Type": "application/json" ],
    body : groovy.json.JsonOutput.toJson([pin : 1, state : 0])
  ], getDeviceIpAndPort(device), [callback: "syncOpState"]))
}

def turnOff() {
  def device = state.device
  log.debug "Updating Konnected Thermostat " + getDeviceIpAndPort(device) + "/device/1 to OFF"
  sendHubCommand(new physicalgraph.device.HubAction([
    method: "PUT",
    path: "/device",
    headers: [ HOST: getDeviceIpAndPort(device), "Content-Type": "application/json" ],
    body : groovy.json.JsonOutput.toJson([pin : 1, state : 1])
  ], getDeviceIpAndPort(device), [callback: "syncOpState"]))
}

void syncOpState(physicalgraph.device.HubResponse hubResponse) {
  def device = getThermostat()
  def newState = hubResponse.json.state == 1 ? "idle" : "cooling"
  log.debug "Received acknowledgement from Konnected Thermostat. Operating state is now: ${newState}"
  device?.updateOpState(newState)
}

def calculateCurrentTemperature() {
	return calculateValue(temperatureCalc, temperatureSensors.currentTemperature)
}

def calculateCurrentHumidity() {
	return calculateValue(humidityCalc, humiditySensors.currentHumidity)
}

def calculateValue(calcMethod, measurements) {
	def result
    switch (calcMethod)  {
    	case "Minimum":
        	result = measurements.min()
            log.debug "Minimum is ${result} of ${measurements}"
            break
        case "Maximum":
        	result = allTemperatures.max()
            log.debug "Maximum is ${result} of ${measurements}"
            break
        case "Median":
            def i = (measurements.size() / 2).intValue()
			if (measurements.size() % 2 == 0) {
                result = (measurements[i-1] + measurements[i]) / 2
            } else {
            	result = measurements[i]
            }
            log.debug "Median is ${result} of ${measurements}"
            break
        default:
        	result = measurements.sum() / measurements.size()
            log.debug "Average is ${result} of ${measurements}"
            break
    }
    return result
}

def temperatureHandler(evt)
{
    def thermostat = getThermostat()
    thermostat.setTemperature(calculateCurrentTemperature())
    evaluateConditions()
}

def humidityHandler(evt)
{
    def thermostat = getThermostat()
    thermostat.setHumidity(calculateCurrentHumidity())
    evaluateConditions()
}

def openCloseHandler(evt) {
	def anyOpen = contactSensors.currentContact.find { contactValue ->
      contactValue == "open"
    }

    if (anyOpen && !state.contactOpenedAt) {
    	log.debug "Konnected Thermostat: A contact was opened at ${evt.date}; starting open timer."
        state.contactOpenedAt = evt.date
        runIn(60 * openContactTime, evaluateConditions)
    } else if (!anyOpen) {
    	log.debug "Konnected Thermostat: All contacts are closed"
        state.contactOpenedAt = null
    	evaluateConditions()
    }
}

def evaluateConditions(evt) {
	def thermostat = getThermostat()
    def locationMode = location.mode
	def currentTemperature = thermostat.currentValue("temperature")
    def heatingSetpoint = thermostat.currentValue("heatingSetpoint")
    def coolingSetpoint = thermostat.currentValue("coolingSetpoint")
    log.debug "Konnected Thermostat: evaluating current temperature: ${currentTemperature}"

	if (energySavingModes.contains(locationMode)) {
    	log.debug "Konnected Thermostat: Mode is ${locationMode}, turn off."
        turnOff()
        return
    }

    if (state.contactOpenedAt) {
    	def openedAt
        def turnOffTime

        use(TimeCategory) {
        	openedAt = Date.parse("yyyy-MM-dd'T'HH:mm:ss", state.contactOpenedAt)
            turnOffTime = openedAt + openContactTime.minutes
        }
        if (turnOfftime <= new Date()) {
            log.debug "Konnected Thermostat: A contact was open more than ${openContactTime} minutes ago at ${openedAt}; turn off."
            turnOff()
            return
        }
    }

    if (thermostat.currentValue("thermostatMode") == "cool") {
    	log.debug "Konnected Thermostat: in cool mode"
        if (currentTemperature > coolingSetpoint) {
        	log.debug "Konnected Thermostat: cooling setpoint ${coolingSetpoint} is lower than current temperature ${currentTemperature}, cool on."
            if (state.contactOpenedAt) {
            	log.debug "Konnected Thermostat: Not turning on because a contact is open."
            	return
            } else {
                coolOn()
            }
        } else {
            log.debug "Konnected Thermostat: current temperature ${currentTemperature} is at or below cooling setpoint ${coolingSetpoint}, turn off."
            turnOff()
        }
    }

    if (thermostat.currentValue("thermostatMode") == "off") {
	    log.debug "Konnected Thermostat: thermostat mode is off, turn off."
        turnOff()
    }
}

private Integer convertHexToInt(hex) { Integer.parseInt(hex,16) }
private String convertHexToIP(hex) { [convertHexToInt(hex[0..1]),convertHexToInt(hex[2..3]),convertHexToInt(hex[4..5]),convertHexToInt(hex[6..7])].join(".") }
