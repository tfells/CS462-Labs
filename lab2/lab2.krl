ruleset wovyn_base {
  meta {
    name "wovyn"
  }
  
  global {
    temperature_threshold = "70"
    to = "+14357035885"
    from = "+19377447606"
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
      valid = tempF.as("Number") > temperature_threshold.as("Number")
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
        "to":to,
        "from":from,
        "message": "The coaxium was getting too hot at " + timestamp + "!"
      }
    }
  }
}
