ruleset wovyn_base {
  meta {
    name "wovyn"
    provides getThreshold, getTo, getLocation, getName
    shares getThreshold, getTo, getLocation, getName
  }

  global {
    getThreshold = function() {
      ent:temperature_threshold.defaultsTo("70")
    }
    getTo = function() {
      ent:to.defaultsTo("+14357035885")
    }
    getLocation = function() {
      ent:location.defaultsTo("BLANK")
    }
    getName = function() {
      ent:name.defaultsTo("BLANK")
    }
  }

  rule update_values {
    select when wovyn updated_values
    pre {
      loc = event:attrs{"location"}
      name = event:attrs{"name"}
      valid = loc && name
      new_threshold = event:attrs{"threshold"}
      sms = event:attrs{"sms"}
    }
    noop();
    fired {
      ent:location := loc
      ent:name := name
      ent:temperature_threshold := new_threshold if new_threshold != "NO"
      ent:to := sms if sms != "NO"
    }
  }


  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      gen = event:attrs{"genericThing"}
    }
    if gen then send_directive("Do", {"something": "Here"})
    fired {
      raise wovyn event "new_temperature_reading" attributes {
        "temperatureF": gen{"data"}{"temperature"}[0]{"temperatureF"},
        "temperatureC": gen{"data"}{"temperature"}[0]{"temperatureC"},
        "timestamp": time:now()
      }
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      tempF = event:attrs{"temperatureF"}
      tempC = event:attrs{"temperatureC"}
      timestamp = event:attrs{"timestamp"}
      valid = tempF.as("Number") > ent:temperature_threshold.defaultsTo("70").as("Number")
    }
    if valid then noop();
    fired {
      raise wovyn event "threshold_violation" attributes {
        "temperatureF": tempF,
        "temperatureC": tempC,
        "timestamp": timestamp
      }
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      tempF = event:attrs{"temperatureF"}
      tempC = event:attrs{"temperatureC"}
      timestamp = event:attrs{"timestamp"}
    }
    if true then noop();
    fired {
      raise message event "send_message" attributes {
        "to":ent:to.defaultsTo("+14357035885"),
        "from":ent:from.defaultsTo("+19377447606"),
        "message": "The coaxium was getting too hot at " + timestamp + "!"
      }
    }
  }
}
