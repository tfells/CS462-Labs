ruleset sensor_profile {
  meta {
    use module wovyn_base alias wb
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    name "sensor_profile"
    shares getSMS, getThreshold, getLocation, getName
  }

  global {
    tags = [meta:rid]
    domains = __testing{"events"}
      .map(function(e){e.get("domain")})
      .unique()
      .sort()

    eventPolicy = { "allow":domains.map(function(d){{"domain":d,"name":"*"}}), "deny":[]}
    queryPolicy = {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}

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

  //Lab 7 stuff
  rule temp_getter {
    select when sensor get_temp
    pre {
      the_eci = ent:subscriptionTx
      corId = event:attr("id")
    }
    event:send(
     { "eci": the_eci,
       "eid": "send_temps", // can be anything, used for correlation
       "domain": "sensor", "type": "cur_temp",
       "attrs": {
         "id": corId,
         "curTemp": wb:getCurTemp(),
         "sensorName": ent:sensorName.defaultsTo("THIS IS VERY WRRONG"),
         "rx": subs:wellKnown_Rx(){"id"}
       }
     })
  }








  rule violation {
    select when message send_message
    pre {
      to = event:attr("to")
      frome = event:attr("from")
      message = event:attr("message")
    }
    event:send({"eci":ent:subscriptionTx,
      "domain":"temp", "name":"violation",
      "attrs": {
        "to":to,
        "from":frome,
        "message":message
      }
    })
  }

  rule pico_ruleset_added {
    select when wrangler ruleset_installed
      where event:attr("rids") >< meta:rid
    pre {
      sensorName = event:attr("sensorName")
      parent_eci = wrangler:parent_eci()
      wellKnown_Rx = event:attr("wellKnown_Rx")
    }
    if ent:channelThing.isnull() then
          wrangler:createChannel(tags,eventPolicy,queryPolicy) setting(channel)
    /* event:send({"eci":parent_eci,
      "domain": "sensors", "type": "subscribe",
      "attrs": {
        "sensorName": sensorName,
        "wellKnown_eci": wellKnown_eci
      }
    }) */
    fired {
      ent:sensorName := event:attr("sensorName")
      ent:wellKnown_Rx := event:attr("wellKnown_Rx")
      ent:channelThing := channel{"id"}
      raise sensor event "new_subscription_request"
    }
  }


  rule make_a_subscription {
    select when sensor new_subscription_request
    event:send({"eci":ent:wellKnown_Rx,
      "domain":"wrangler", "name":"subscription",
      "attrs": {
        "wellKnown_Tx":subs:wellKnown_Rx(){"id"},
        "Rx_role":"manager", "Tx_role":"sensor",
        "name":ent:sensorName+"-sensor", "channel_type":"subscription"
      }
    })
  }


  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      my_role = event:attr("Rx_role")
      their_role = event:attr("Tx_role")
    }
    if my_role=="sensor" && their_role=="manager" then noop()
    fired {
      raise wrangler event "pending_subscription_approval"
        attributes event:attrs
      ent:subscriptionTx := event:attr("Tx")
    } else {
      raise wrangler event "inbound_rejection"
        attributes event:attrs
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
