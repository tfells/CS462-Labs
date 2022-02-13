ruleset sensor_profile {
  meta {
    use module wovyn_base alias wb
    name "sensor_profile"
    shares getSMS, getThreshold, getLocation, getName
  }

  global {

    getSMS = function() {
      wb:getTo()
    }
    getThreshold = function() {
      wb:getThreshold()
    }
    getLocation = function() {
      wb:getLocation()
    }
    getName = function() {
      wb:getName()
    }

  }

  rule update_profile {
    select when sensor profile_updated
    pre {
      loc = event:attrs{"location"}
      name = event:attrs{"name"}
      valid = loc && name
      new_threshold = ((event:attrs{"threshold"}) => event:attrs{"threshold"} | "NO")
      sms = ((event:attrs{"sms"}) => event:attrs{"sms"} | "NO")
    }
    if valid then noop();
    fired {
      raise wovyn event "updated_values" attributes {
        "location":loc,
        "name":name,
        "threshold": new_threshold,
        "sms": sms
      }
    }
  }
}
