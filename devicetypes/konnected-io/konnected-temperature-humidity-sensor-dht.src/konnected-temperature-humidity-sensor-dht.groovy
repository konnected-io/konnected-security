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
  definition (name: "Konnected Temperature & Humidity Sensor (DHT)", namespace: "konnected-io", author: "konnected.io") {
    capability "Temperature Measurement"
    capability "Relative Humidity Measurement"
  }

  tiles {
    multiAttributeTile(name:"main", type:"thermostat", width:6, height:4) {
        tileAttribute("device.temperature", key: "PRIMARY_CONTROL") {
            attributeState("temperature", label:'${currentValue}', unit:"F", defaultState: true)
        }
        tileAttribute("device.humidity", key: "SECONDARY_CONTROL") {
            attributeState("humidity", label:'${currentValue}%', unit:"%", defaultState: true)
        }
    }
    main "main"
    details "main"
  }
}


// Update state sent from parent app
def updateStates(state) {
  def measurements = state.replaceAll(',','.').split("_")
  def temperature = new BigDecimal(measurements[0])
  def humidity = new BigDecimal(measurements[1])
  if (location.getTemperatureScale() == 'F') {
  	temperature = temperature * 9 / 5 + 32
  }

  log.debug "Temperature: $temperature"
  log.debug "Humidity: $humidity"

  sendEvent(name: "temperature", value: temperature.setScale(1, BigDecimal.ROUND_HALF_UP), unit: location.getTemperatureScale())
  sendEvent(name: "humidity", value: humidity.setScale(0, BigDecimal.ROUND_HALF_UP), unit: '%')
}