/**
 *  Konnected Key Switch
 *
 *  Copyright 2019 Peter Babinski
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
metadata {
  definition (name: "Konnected Key Switch", namespace: "konnected-io", author: "tailg8nj", mnmn: "SmartThings", vid: "generic-switch") {
    capability "Actuator"
    capability "Button"
    command "push"
    command "hold"
  }

  preferences {
    input name: "invertTrigger", type: "bool", title: "Low Level Trigger",
          description: "Select if the attached relay uses a low-level trigger. Default is high-level trigger"
    input name: "awayDelay", type: "number", title: "Away Momentary Delay",
          description: "Off delay (in milliseconds)"
    input name: "stayDelay", type: "number", title: "Stay Momentary Delay",
          description: "Off delay (in milliseconds)"
  }

  tiles {
    standardTile("button", "device.button", width: 1, height: 1) {
      state "default", label: "", icon: "st.Home.home3", backgroundColor: "#ffffff"
    }
    standardTile("push", "device.button", width: 1, height: 1, decoration: "flat") {
      state "default", label: "Arm Away", backgroundColor: "#ffffff", action: "push"
    } 
    standardTile("hold", "device.button", width: 1, height: 1, decoration: "flat") {
      state "default", label: "Arm Stay", backgroundColor: "#ffffff", action: "hold"
    }          
    main "button"
    details(["button","push","hold"])
  }
}

def updated() {
  parent.updateSettingsOnDevice()
}

def updatePinState(Integer state) {
  def off = invertTrigger ? 1 : 0
  if (state == off) {
    sendEvent(name: "switch", value: "off", isStateChange: true, display: false)
  } else {
    sendEvent(name: "switch", value: "on", isStateChange: true, display: false)
    def delaySeconds = (momentaryDelay ?: 1000) / 1000 as Integer
    runIn(Math.max(delaySeconds, 1), switchOff)
  }
}

def switchOff() {
  sendEvent(name: "switch", value: "off", isStateChange: true, display: false)
}

def off() {
  def val = invertTrigger ? 1 : 0
  parent.deviceUpdateDeviceState(device.deviceNetworkId, val)
}

def on() {
  push()
}

def push() {
  def val = invertTrigger ? 0 : 1
  parent.deviceUpdateDeviceState(device.deviceNetworkId, val, [
    momentary : pushDelay ?: 1000
  ])
}

def hold() {
  def val = invertTrigger ? 0 : 1
  parent.deviceUpdateDeviceState(device.deviceNetworkId, val, [
    momentary : holdDelay ?: 3000
  ])
}

def triggerLevel() {
  return invertTrigger ? 0 : 1
}

def currentBinaryValue() {
  if (device.currentValue('switch') == 'on') {
    invertTrigger ? 0 : 1
  } else {
    invertTrigger ? 1 : 0
  }
}
