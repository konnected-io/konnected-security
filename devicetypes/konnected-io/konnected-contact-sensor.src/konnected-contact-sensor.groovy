/**
 *  Konnected Contact Sensor
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
  definition (name: "Konnected Contact Sensor", namespace: "konnected-io", author: "konnected.io") {
    capability "Contact Sensor"
    capability "Sensor"
  }
  preferences {
    section("prefs") {
      input(name: "openDisplayLabel", type: "text", title: "Enter the text to display when the contact is open.",  required: true)
      input(name: "closedDisplayLabel", type: "text", title: "Enter the text to display when the contact is closed.", required: true)
    }
  }
  tiles {
    multiAttributeTile(name:"contact", type: "generic", width: 6, height: 4, canChangeIcon: true) {
      tileAttribute ("device.contactDisplay", key: "PRIMARY_CONTROL") {
        attributeState ("closed", label: "Closed", icon:"st.contact.contact.closed", backgroundColor:"#00a0dc")
        attributeState ("open",   label: "Open",   icon:"st.contact.contact.open",   backgroundColor:"#e86d13")
      }
    }
    main "contact"
    details "contact"
  }
}

def updated() {
	// log.debug("Updated called.  Make sure to update labels.")
  updateLabels(device.currentValue("contact"))
}

//Update state sent from parent app
def setStatus(state) { 
  switch(state) {
    case "0" :
      sendEvent(name: "contact", value: "closed")
      break
    case "1" :
      sendEvent(name: "contact", value: "open")
      break
    default:
      sendEvent(name: "contact", value: "open") 
      break
  }
  log.debug("$device.label is " + device.currentValue("contact"))
  updateLabels(device.currentValue("contact"))
}

def updateLabels (String value) {
	// log.debug("updateLabels called.  Passed value is $value.  openDisplayLabel is $openDisplayLabel.  closedDisplayLabel is $closedDisplayLabel.")
	// Update tile with custom labels
  if (value.equals("open")) {
    sendEvent(name: "contactDisplay", value: openDisplayLabel, isStateChange: true);
	} else {
		sendEvent(name: "contactDisplay", value: closedDisplayLabel, isStateChange: true)
	}
}
