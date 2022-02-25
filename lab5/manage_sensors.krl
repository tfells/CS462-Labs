ruleset sensor_manager {
  meta {
    name "sensor_manager"
    use module io.picolabs.wrangler alias wrangler
    shares showChildren, sensors
  }

  global {
    temperature_store = "file:///Users/travis/me%20files/School%20Years/Senior%20Year/cs462/lab4/"
    defaultThresh = "90"
    defaultSms = "+14357035885"

    showChildren = function() {
      wrangler:children()
    }
    sensors = function() {
      ent:sensors
    }

  }




  rule initialize_sections {
    select when sensors needs_initialization
    always {
      ent:sensors := {}
    }
  }
  rule manage_sensors {
    select when sensor new_sensor
    pre {
      newSensorName = event:attr("name")
      exists = ent:sensors && ent:sensors >< newSensorName
    }
    if exists then
      send_directive("sensors_ready", {"sensor name":newSensorName})
    notfired {
      raise wrangler event "new_child_request"
      attributes { "name": newSensorName,
                 "backgroundColor": "#ff69b4",
                 "sensorName": newSensorName}
    }
  }

  rule update_profile {
    select when sensor profile_updated
    pre {
      sensorName = event:attr("sensorName")
      the_eci = event:attr("eci")
    }
    event:send(
     { "eci": the_eci,
       "eid": "update_values", // can be anything, used for correlation
       "domain": "wovyn", "type": "updated_values",
       "attrs": {
         "location": "Here",
         "name": sensorName,
         "threshold": defaultThresh,
         "sms": defaultSms
       }
     })
  }

  rule delete_sensor {
    select when sensor unneeded_sensor
    pre {
      sensorName = event:attr("sensorName")
      exists = ent:sensors && ent:sensors >< sensorName
      eci_to_delete = ent:sensors{[sensorName,"eci"]}
    }
      if exists && eci_to_delete then noop();
    fired {
      raise wrangler event "child_deletion_request"
        attributes {"eci": eci_to_delete};
      clear ent:sensors{sensorName}
    }
  }




  rule store_new_section {
    select when wrangler new_child_created
    pre {
      the_eci = {"eci": event:attr("eci")}
      nameOfSensor = event:attr("sensorName")
    }
    if nameOfSensor.klog("found sensor") then
       event:send(
        { "eci": the_eci.get("eci"),
          "eid": "install-ruleset", // can be anything, used for correlation
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": temperature_store,
            "rid": "lab3",
            "config": {},
            "sensorName": nameOfSensor
          }
        })

    fired {
      ent:sensors{nameOfSensor} := the_eci
      raise sensor event "ruleset_2"
      attributes { "eci": event:attr("eci"), "sensorName": nameOfSensor }
    }
  }

 rule install_ruleset_2 {
    select when sensor ruleset_2
    pre {
      the_eci = {"eci": event:attr("eci")}
      nameOfSensor = event:attr("sensorName")
    }
    if nameOfSensor.klog("found section_id") then
       event:send(
        { "eci": the_eci.get("eci"),
          "eid": "install-ruleset", // can be anything, used for correlation
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": temperature_store,
            "rid": "io.picolabs.wovyn.emitter",
            "config": {},
            "sensorName": nameOfSensor
          }
        })

    fired {
      raise sensor event "ruleset_3"
      attributes { "eci": event:attr("eci"), "sensorName": nameOfSensor }
    }
  }
  rule store_new_section2 {
    select when sensor ruleset_3
    pre {
      the_eci = {"eci": event:attr("eci")}
      nameOfSensor = event:attr("sensorName")
    }
    if nameOfSensor.klog("found section_id") then
       event:send(
        { "eci": the_eci.get("eci"),
          "eid": "install-ruleset", // can be anything, used for correlation
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": temperature_store,
            "rid": "lab2",
            "config": {},
            "sensorName": nameOfSensor
          }
        })

    fired {
      raise sensor event "ruleset_4"
      attributes { "eci": event:attr("eci"), "sensorName": nameOfSensor }
    }
  }
  rule store_new_section3 {
    select when sensor ruleset_4
    pre {
      the_eci = {"eci": event:attr("eci")}
      nameOfSensor = event:attr("sensorName")
    }
    if nameOfSensor.klog("found section_id") then
       event:send(
        { "eci": the_eci.get("eci"),
          "eid": "install-ruleset", // can be anything, used for correlation
          "domain": "wrangler", "type": "install_ruleset_request",
          "attrs": {
            "absoluteURL": temperature_store,
            "rid": "sensor_profile",
            "config": {},
            "sensorName": nameOfSensor
          }
        })
    fired {
      raise sensor event "profile_updated"
      attributes {"eci": event:attr("eci"), "sensorName": nameOfSensor}
    }
  }

}
