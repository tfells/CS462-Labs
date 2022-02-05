ruleset temperature_store {
  meta {
    name "wovyn"
    provides temperatures, threshold_violations, inrange_temperatures
    shares getTimes, getTemps, getTimesViolated, getTempsViolated, temperatures, threshold_violations, inrange_temperatures
  }
  
  global {
    temperature_threshold = "70"
    to = "+14357035885"
    from = "+19377447606"

    getTimes = function() { 
      ent:times
    }
    getTemps = function() { 
      ent:temps
    }
    getTimesViolated = function() { 
      ent:timeVios
    }
    getTempsViolated = function() { 
      ent:tempVios
    }

    temperatures = function() {
      returnval = [ent:temps, ent:times].pairwise(function(x,y) {x.append(y)}); 
      returnval
    }
    threshold_violations = function() {
      returnval = [ent:tempVios, ent:timeVios].pairwise(function(x,y) {x.append(y)}); 
      returnval
    }
    inrange_temperatures = function() {
      temp1 = [ent:temps, ent:times].pairwise(function(x,y) {x.append(y)}); 
      returnval = temp1.filter(function(x) {x[0]<temperature_threshold});      
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
      ent:temps := ent:temps.defaultsTo([]).append(temp)
      ent:times := ent:times.defaultsTo([]).append(timestamp)
    }
  }

  rule collect_threshold_violations {
    select when wovyn threshold_violation
    pre {
      temp = event:attrs{"temperatureF"}
      timestamp = event:attrs{"timestamp"}
    }
    always {
      ent:tempVios := ent:tempVios.defaultsTo([]).append(temp)
      ent:timeVios := ent:timeVios.defaultsTo([]).append(timestamp)
    }
  }

  rule clear_temperatures {
    select when sensor reading_reset 
    always {
      clear ent:tempVios
      clear ent:timeVios
      clear ent:temps
      clear ent:times
    }
  }
}
