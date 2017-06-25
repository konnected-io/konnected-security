/**
 *  Konnected Alarm Panel (Connect)
 *
 *  Copyright 2017 konnected.io
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
definition(
  name:        "Konnected Alarm Panel(Connect)",
  namespace:   "konnected-io",
  author:      "konnected.io",
  description: "Konnected Alarm Panel",
  category:    "Safety & Security",
  iconUrl:     "https://raw.githubusercontent.com/konnected-io/SmartThings/master/images/icons/KonnectedAlarmPanel.png",
  iconX2Url:   "https://raw.githubusercontent.com/konnected-io/SmartThings/master/images/icons/KonnectedAlarmPanel@2x.png",
  iconX3Url:   "https://raw.githubusercontent.com/konnected-io/SmartThings/master/images/icons/KonnectedAlarmPanel@3x.png",
  singleInstance: true
)
mappings {
  path("/device/:mac/:id/:deviceState") { action: [ PUT: "childDeviceStateUpdate"] }
}
preferences {
  page(name: "pageDiscovery",   install: false, uninstall: true, content: "pageDiscovery", nextPage: "pageConfiguration" )
  page(name: "pageConfiguration", install: true,  uninstall: true, content: "pageConfiguration")
}
def installed() { 
  log.info "installed(): Installing SmartApp"
  initialize() 
  runEvery3Hours(discoverySearch)
}
def updated() { 
  log.info "updated(): Updating SmartApp"
  initialize() 
}
def uninstalled() {
  log.info "uninstall(): Uninstalling SmartApp"
  revokeAccessToken()
  //Uninstall SmartApp, tell device that access is revoked and remove all the settings
  log.info "uninstall(): Removing device settings"
  def body = [
    token : "",
    apiUrl : "",
    sensors : [],
    actuators : []
  ]
  def selectedAlarmPanel = [] + getSelectedAlarmPanel()
  selectedAlarmPanel.each { 
    sendHubCommand(new physicalgraph.device.HubAction([
      method: "PUT", 
      path: "/settings", 
      headers: [ HOST: it.host, "Content-Type": "application/json" ], 
      body : groovy.json.JsonOutput.toJson(body)
    ], it.host )) 
  }
}
def initialize() {
  unsubscribe()
  unschedule()
  discoverySubscribtion(true)  
  childDeviceConfiguration()
  deviceUpdateSettings()
  state.pageConfigurationRefresh = 2
}

//Page : 1 : Discovery page - search and select devices
def pageDiscovery() {
  if(!state.accessToken) { createAccessToken() }  
  if(!state.pageConfigurationRefresh) { state.pageConfigurationRefresh = 2 }
  dynamicPage(name: "pageDiscovery", nextPage: "pageConfiguration", refreshInterval: state.pageConfigurationRefresh) {
    state.pageConfigurationRefresh =  state.pageConfigurationRefresh + 3
    discoverySubscribtion()
    discoverySearch()
    discoveryVerification()
    def alarmPanels = pageDiscoveryGetAlarmPanels()
    section("Please wait while we discover your device") {
      input(name: "selectedAlarmPanels", type: "enum", title: "Select Alarm Panel (${alarmPanels.size() ?: 0} found)", required: true, multiple: true, options: alarmPanels, defaultValue: settings.selectedAlarmPanels, submitOnChange: true)
    }
  }    
}
//Page : 2 : Configure sensors and alarms connected to the panel
def pageConfiguration() {
  def configuredAlarmPanels = [] + getSelectedAlarmPanel()
  dynamicPage(name: "pageConfiguration") {
    configuredAlarmPanels.each { alarmPanel ->
      section(hideable: true, "AlarmPanel_${alarmPanel.mac[-6..-1]}") {
        for ( i in [1, 2, 5, 6, 7, 8]) {
          def deviceTypeDefaultValue = (settings."deviceType_${alarmPanel.mac}_${i}") ? settings."deviceType_${alarmPanel.mac}_${i}" : ""
          def deviceLabelDefaultValue = (settings."deviceLabel_${alarmPanel.mac}_${i}") ? settings."deviceLabel_${alarmPanel.mac}_${i}" : ""
          input(name: "deviceType_${alarmPanel.mac}_${i}", type: "enum", title:"Pin ${i} Device Type", required: false, multiple: false, options: pageConfigurationGetDeviceType(), defaultValue: deviceTypeDefaultValue, submitOnChange: true)
          if (settings."deviceType_${alarmPanel.mac}_${i}") {
            input(name: "deviceLabel_${alarmPanel.mac}_${i}", type: "text", title:"Pin ${i} Device Label", required: false, defaultValue: deviceLabelDefaultValue)
          } 
        }
      }
    }
  }
}
Map pageConfigurationGetDeviceType() { 
  return [
    "contact" : "Open/Close Sensor", 
    "motion"  : "Motion Sensor", 
    "smoke"   : "Smoke Detector",
    "siren"   : "Siren/Strobe",
    "switch"  : "Panic Button"
  ] 
}
Map pageDiscoveryGetAlarmPanels() {
  def alarmPanels = [:]
  def verifiedAlarmPanels = getAlarmPanels().findAll{ it.value.verified == true }
  verifiedAlarmPanels.each { alarmPanels["${it.value.mac}"] = it.value.name ?: "AlarmPanel_${it.value.mac[-6..-1]}" }
  return alarmPanels
}

//Retrieve selected device
def getSelectedAlarmPanel(mac) {
  if (mac) {
    return state.alarmPanel.find { it.mac == mac } 
  } else {
    state.alarmPanel = []
    def configuredAlarmPanels = [] + settings.selectedAlarmPanels
    configuredAlarmPanels.each { alarmPanel ->
      def selectedAlarmPanel = getAlarmPanels().find { it.value.mac == alarmPanel }
      state.alarmPanel = state.alarmPanel + [
        mac : selectedAlarmPanel.value.mac,
        ip  : selectedAlarmPanel.value.networkAddress,
        port: selectedAlarmPanel.value.deviceAddress,
        hub : selectedAlarmPanel.value.hub,
        host: "${convertHexToIP(selectedAlarmPanel.value.networkAddress)}:${convertHexToInt(selectedAlarmPanel.value.deviceAddress)}"
      ]
    }
    return state.alarmPanel
  }
}
//Retrieve devices saved in state
def getAlarmPanels() {
  if (!state.devices) { state.devices = [:] }
  return state.devices
}

//Device Discovery : Device Type 
def discoveryDeviceType() { return "urn:schemas-konnected-io:device:AlarmPanel:1" }
//Device Discovery : Send M-Search to multicast
def discoverySearch() { sendHubCommand(new physicalgraph.device.HubAction("lan discovery ${discoveryDeviceType()}", physicalgraph.device.Protocol.LAN)) }
//Device Discovery : Subscribe to SSDP events
def discoverySubscribtion(force=false) {
  if (force) {
    unsubscribe()
    state.subscribe = false
  }
  if(!state.subscribe) {
    subscribe(location, "ssdpTerm.${discoveryDeviceType()}", discoverySearchHandler, [filterEvents:false])
    state.subscribe = true
  }
}
//Device Discovery : Handle search response
def discoverySearchHandler(evt) {
  def event = parseLanMessage(evt.description)
  event << ["hub":evt?.hubId]
  def devices = getAlarmPanels()
  String ssdpUSN = event.ssdpUSN.toString()
  if (!devices."${ssdpUSN}") { devices << ["${ssdpUSN}": event] }
  if (state.alarmPanel) {
    state.alarmPanel.each {
      if (it.mac == event.mac) {
        if (it.ip != event.networkAddress) or (it.port != event.deviceAddress) {
          it.ip   = event.networkAddress 
          it.port = event.deviceAddress
          it.host = "${convertHexToIP(event.networkAddress)}:${convertHexToInt(event.deviceAddress)}"
        }
      }
    }
  }
}
//Device Discovery : Verify search response by retrieving XML
def discoveryVerification() {
  def alarmPanels = getAlarmPanels().findAll { it?.value?.verified != true }
  alarmPanels.each {
    String host = "${convertHexToIP(it.value.networkAddress)}:${convertHexToInt(it.value.deviceAddress)}"
    sendHubCommand(new physicalgraph.device.HubAction("""GET ${it.value.ssdpPath} HTTP/1.1\r\nHOST: ${host}\r\n\r\n""", physicalgraph.device.Protocol.LAN, host, [callback: discoveryVerificationHandler]))
  }
}
//Device Discovery : Handle verification response
def discoveryVerificationHandler(physicalgraph.device.HubResponse hubResponse) {
  def body = hubResponse.xml
  def devices = getAlarmPanels()
  def device = devices.find { it?.key?.contains(body?.device?.UDN?.text()) }
  if (device) { device.value << [name: body?.device?.roomName?.text(), model:body?.device?.modelName?.text(), serialNumber:body?.device?.serialNum?.text(), verified: true] }
}

//Child Devices : Get device type
def childDeviceGetDeviceType(value) {
  def deviceType = ""
    switch(value) {
      case "contact": 
        deviceType = "Konnected Contact Sensor"
        break
      case "motion": 
        deviceType = "Konnected Motion Sensor"
        break
      case "smoke":
        deviceType = "Konnected Smoke Sensor"
        break
      case "siren":
        deviceType = "Konnected Siren/Strobe"
        break
      case "switch":
        deviceType = "Konnected Panic Button"
        break
      default:
        deviceType = ""
        break
    }
  return deviceType
}

//Child Devices : create/delete child devices from SmartThings app selection
def childDeviceConfiguration() {
  def selecteAlarmPanels = [] + getSelectedAlarmPanel()
  settings.each { name , value ->
    def nameValue = name.split("\\_")
    if (nameValue[0] == "deviceType") {
      def selectedAlarmPanel = getSelectedAlarmPanel().find { it.mac == nameValue[1] } 
      def deviceDNI = [ selectedAlarmPanel.mac, "${nameValue[2]}"].join('|') 
      def deviceLabel = settings."deviceLabel_${nameValue[1]}_${nameValue[2]}"
      def deviceType = childDeviceGetDeviceType(value)
      def deviceChild = getChildDevice(deviceDNI)      
      if (!deviceChild) { 
        if (deviceType != "") {
          addChildDevice("konnected-io", deviceType, deviceDNI, selectedAlarmPanel.hub, [ "label": deviceLabel ? deviceLabel : deviceType ]) 
        }
      } else {
        if (deviceChild.label != deviceLabel) 
          deviceChild.label = deviceLabel
        if (deviceChild.name != deviceType) {
          deleteChildDevice(deviceDNI)
          if (deviceType != "") {
            addChildDevice("konnected-io", deviceType, deviceDNI, selectedAlarmPanel.hub, [ "label": deviceLabel ? deviceLabel : deviceType ]) 
          }
        }
      }
    }
  }
  def deleteChildDevices = getAllChildDevices().findAll { childDeviceGetDeviceType(settings."deviceType_${it.deviceNetworkId.split("\\|")[0]}_${it.deviceNetworkId.split("\\|")[1]}") == "" }
  deleteChildDevices.each { deleteChildDevice(it.deviceNetworkId) }  
}
//Child Devices : update state of child device sent from nodemcu
def childDeviceStateUpdate() {
  def device = getChildDevice(params.mac.toUpperCase() + "|" + params.id)
  if (device) device.setStatus(params.deviceState)
}

//Device : update NodeMCU with token, url, sensors, actuators from SmartThings 
def deviceUpdateSettings() {
  if(!state.accessToken) { createAccessToken() }  
  def body = [
    token : state.accessToken,
    apiUrl : apiServerUrl + "/api/smartapps/installations/" + app.id,
    sensors : [],
    actuators : []
  ]
  getAllChildDevices().each {
    if (it.name != "Konnected Siren/Strobe") { 
      body.sensors = body.sensors + [ pin : it.deviceNetworkId.split("\\|")[1] ] 
    } else {
      body.actuators = body.actuators + [ pin : it.deviceNetworkId.split("\\|")[1] ] 
    }
  }
  def selectedAlarmPanel = [] + getSelectedAlarmPanel()
  selectedAlarmPanel.each { 
    sendHubCommand(new physicalgraph.device.HubAction([
      method: "PUT", 
      path: "/settings", 
      headers: [ HOST: it.host, "Content-Type": "application/json" ], 
      body : groovy.json.JsonOutput.toJson(body)
    ], it.host )) 
  }
}
//Device: update NodeMCU with state of device changed from SmartThings
def deviceUpdateDeviceState(deviceDNI, deviceState) {
  def deviceId = deviceDNI.split("\\|")[1]
  def deviceMac = deviceDNI.split("\\|")[0]
  def body = [ pin : deviceId, state : deviceState ]
  def selectedAlarmPanel = getSelectedAlarmPanel(deviceMac)
  sendHubCommand(new physicalgraph.device.HubAction([
    method: "PUT", 
    path: "/device", 
    headers: [ HOST: selectedAlarmPanel.host, "Content-Type": "application/json" ], 
    body : groovy.json.JsonOutput.toJson(body)
  ], selectedAlarmPanel.host))
}

private Integer convertHexToInt(hex) { Integer.parseInt(hex,16) }
private String convertHexToIP(hex) { [convertHexToInt(hex[0..1]),convertHexToInt(hex[2..3]),convertHexToInt(hex[4..5]),convertHexToInt(hex[6..7])].join(".") }
