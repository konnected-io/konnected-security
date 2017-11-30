/**
 *  Konnected Water Leak Sensor
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
  definition (name: "Konnected Water Sensor", namespace: "konnected-io", author: "konnected.io") {
    capability "Water Sensor"
    capability "Sensor"
  }
  tiles {
    multiAttributeTile(name:"main", type: "generic", width: 6, height: 4, canChangeIcon: true) {
      tileAttribute ("device.water", key: "PRIMARY_CONTROL") {
      	attributeState ("dry", label: "Dry", icon: "st.alarm.water.dry", backgroundColor: "#ffffff")
		    attributeState ("wet", label: "Wet", icon: "st.alarm.water.wet", backgroundColor: "#00A0DC")
      }
    }
    main "main"
    details "main"
  }
}

//Update state sent from parent app
def setStatus(state) { 
  switch(state) {
    case "0" :
      sendEvent(name: "water", value: "wet")
      log.debug "$device.label is wet"
      break
    case "1" :
      sendEvent(name: "water", value: "dry")
      log.debug "$device.label is dry"
      break
    default:
      sendEvent(name: "water", value: "dry") 
      break
  }
}
