ruleset timing_tracker {
  meta {
    shares entries
  }
  global {
    entries = function() {
      ent:timings.defaultsTo({}).values()
    }
  }
  rule timing_first_use {
    select when timing started or timing finished
    if ent:timings then noop()
    notfired {
      ent:timings := {}
    }
  }
  rule timing_started {
    select when timing started number re#n0*(\d+)#i setting(ordinal_string)
    pre {
      key = "N" + ordinal_string
    }
    if ent:timings >< key then noop()
    notfired {
      ent:timings{key} := {
        "ordinal": ordinal_string.as("Number"),
        "number": event:attr("number"),
        "name": event:attr("name"),
        "time_out": time:now() }
    }
  }
  rule timing_finished {
    select when timing finished number re#n0*(\d+)#i setting(ordinal_string)
    pre {
      key = "N" + ordinal_string
    }
    if ent:timings >< key then noop()
    fired {
      ent:timings{[key,"time_in"]} := time:now()
    }
  }
}
