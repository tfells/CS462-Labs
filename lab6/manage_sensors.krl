ruleset sensor_manager {
  meta {
    name "sensor_manager"
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    use module org.twilio.sdk alias sdk

    shares showChildren, sensors
  }

  global {
    //updated this to reflect lab 6 and created a new copy for lab 6
    temperature_store = "file:///Users/travis/me%20files/School%20Years/Senior%20Year/cs462/lab6/"
    defaultThresh = "90"
    defaultSms = "+14357035885"

    showChildren = function() {
      wrangler:children()
    }
    sensors = function() {
      ent:sensors
    }

  }

  //Lab 6 stuff
  rule send_message {
    select when temp violation

    pre {
      to = event:attrs{"to"}.defaultsTo("+14357035885")
      from = event:attrs{"from"}
      bodyText = event:attrs{"message"}
      valid = true
    }
    if valid then sdk:sendMessage(to, from, bodyText)
  }

  rule sub_added {
    select when wrangler subscription_added
    pre {
      temp = event:attrs.klog("HRE");
      wellKnown_Tx = event:attr("wellKnown_Tx").klog("This?")
      name = event:attr("name")
    }
    noop();
    fired {
      ent:txs{wellKnown_Tx} := name
    }
  }

  rule introduce_Subscription {
    select when manager introduce
    pre {
      wellKnown_Tx = event:attr("wellKnown_Tx")
      wellKnown_Rx = event:attr("wellKnown_Rx")
      sensorName = event:attr("nameOfSensor")
    }
    event:send({"eci":wellKnown_Tx,
      "domain":"wrangler", "name":"subscription",
      "attrs": {
        "wellKnown_Tx":wellKnown_Rx,
        "Rx_role":"manager", "Tx_role":"sensor",
        "name":sensorName+"-sensor", "channel_type":"subscription"
      }
    })
  }








  //Lab 5 stuff
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
            "sensorName": nameOfSensor,
            "wellKnown_Rx": subs:wellKnown_Rx(){"id"}
          }
        })
    fired {
      raise sensor event "profile_updated"
      attributes {"eci": event:attr("eci"), "sensorName": nameOfSensor}
    }
  }

}
