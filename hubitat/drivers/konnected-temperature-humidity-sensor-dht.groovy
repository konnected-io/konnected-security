/**
 *  Konnected Temperature & Humidity Sensor (DHT)
 *
 *  Copyright 2018 Konnected Inc (https://konnected.io)
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
  definition (name: "Konnected Temperature & Humidity Sensor (DHT)", namespace: "konnected-io", author: "konnected.io", mnmn: "SmartThings", vid: "generic-humidity") {
    capability "Temperature Measurement"
    capability "Relative Humidity Measurement"
  }

  preferences {
    input name: "pollInterval", type: "number", title: "Polling Interval (minutes)",
      defaultValue: defaultPollInterval(),
      description: "Frequency of sensor updates"
  }

}

def updated() {
  parent.updateSettingsOnDevice()
}

// Update state sent from parent app
def updateStates(states) {
  def temperature = new BigDecimal(states.temp)
  if (location.getTemperatureScale() == 'F') {
  	temperature = temperature * 9 / 5 + 32
  }
  sendEvent(name: "temperature", value: temperature.setScale(1, BigDecimal.ROUND_HALF_UP), unit: location.getTemperatureScale())

  def humidity
  if (states.humi) {
    humidity = new BigDecimal(states.humi)
    sendEvent(name: "humidity", value: humidity.setScale(0, BigDecimal.ROUND_HALF_UP), unit: '%')
  }

  log.info "Temperature: $temperature, Humidity: $humidity"
}

def pollInterval() {
  return pollInterval.isNumber() ? pollInterval : defaultPollInterval()
}

def defaultPollInterval() {
  return 3 // minutes
}
