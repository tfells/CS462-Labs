ruleset temperature_store {
  meta {
    name "wovyn"
    provides temperatures, threshold_violations, inrange_temperatures
    shares getTemps, getTimesViolated, getTempsViolated, temperatures, threshold_violations, inrange_temperatures
  }

  global {
    getTemps = function() {
      ent:temps.defaultsTo({})
    }
    getTimesViolated = function() {
      ent:timeVios
    }
    getTempsViolated = function() {
      ent:tempVios.defaultsTo({})
    }

    temperatures = function() {
      returnval = ent:temps.defaultsTo({})
      returnval
    }
    threshold_violations = function() {
      returnval = ent:tempVios.defaultsTo({})
      returnval
    }
    inrange_temperatures = function() {
      temp1 = [ent:temps, ent:times].pairwise(function(x,y) {x.append(y)});
      returnval = temp1.filter(function(x) {x[0]<ent:temperature_threshold});
      returnval
    }

  }

  rule collect_temperatures {
    select when wovyn new_temperature_reading
    pre {
      temp = event:attrs{"temperatureF"}
      timestamp = event:attrs{"timestamp"}
    }
    always {
      ent:temps{ent:counter.defaultsTo(0)} := {
      "temp": temp,
      "time": timestamp }
      ent:counter := ent:counter.as("Number")+1;
    }
  }

  rule collect_threshold_violations {
    select when wovyn threshold_violation
    pre {
      temp = event:attrs{"temperatureF"}
      timestamp = event:attrs{"timestamp"}
    }
    always {
      ent:tempVios{ent:counter2.defaultsTo(0)} := {
      "temp": temp,
      "time": timestamp }
      ent:counter2 := ent:counter2.as("Number")+1;
    }
  }

  rule clear_temperatures {
    select when sensor reading_reset
    always {
      clear ent:tempVios
      clear ent:temps
      ent:counter := 0;
      ent:counter2 := 0;
    }
  }
}
