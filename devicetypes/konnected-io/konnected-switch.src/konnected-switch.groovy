/**
 *  Konnected Switch
 *
 *  Copyright 2017 konnected.io
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
  definition (name: "Konnected Switch", namespace: "konnected-io", author: "konnected.io") {
    capability "Switch"
    capability "Actuator"
  }

  preferences {
  	input name: "triggerLevel", type: "enum", title: "Relay Trigger Type", options: ["High Level Trigger","Low Level Trigger"]
  }

  tiles {
    multiAttributeTile(name:"main", type: "generic", width: 6, height: 4, canChangeIcon: true) {
      tileAttribute ("device.switch", key: "PRIMARY_CONTROL") {
        attributeState ("off",  label: "Off",    icon:"st.switches.switch.off", action:"switch.on",   backgroundColor:"#ffffff")
        attributeState ("on",   label: "On",     icon:"st.switches.switch.on",  action:"switch.off",  backgroundColor:"#00a0dc")
      }
    }
    main "main"
    details "main"
  }
}

def off() {
  sendEvent([name: "switch", value: "off"])
  def val = triggerLevel == "Low Level Trigger" ? 1 : 0
  parent.deviceUpdateDeviceState(device.deviceNetworkId, val)
}

def on() {
  sendEvent([name: "switch", value: "on"])
  def val = triggerLevel == "Low Level Trigger" ? 0 : 1
  parent.deviceUpdateDeviceState(device.deviceNetworkId, val)
}
