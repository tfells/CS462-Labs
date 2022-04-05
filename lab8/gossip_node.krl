ruleset gossip_node {
  meta {
    use module wovyn_base alias wb
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    name "sensor_profile"
    shares getID, getSeq, getMessageID, makeRumor, getPeers, getReadings, makeSeen, getPeerSeen, checkSched, findRumorToSend, getState
  }


  global {
    tags = [meta:rid]
    domains = __testing{"events"}
      .map(function(e){e.get("domain")})
      .unique()
      .sort()

    eventPolicy = { "allow":domains.map(function(d){{"domain":d,"name":"*"}}), "deny":[]}
    queryPolicy = {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}

    getState = function() {
      ent:state.defaultsTo("on")
    }
    getID = function() {
      ent:myID
    }
    getSeq = function() {
      ent:curSeq
    }
    getMessageID = function() {
      mID = ent:myID + ":" + ent:curSeq
      mID
    }
    getPeers = function() {
      ent:peers
    }
    getPeerSeen = function() {
      ent:peerSeen.defaultsTo({})
    }
    makeRumor = function(me, seq, temp) {
      boom = {"MessageID": (me) => (me + ":" + seq) | getMessageID(),
              "SensorID": (me) => me | ent:myID,
              "Temperature": (me) => temp | wb:getCurTemp(),
              "Timestamp": time:now(),
              "sequence": (me) => seq | ent:curSeq }
      boom
    }
    checkSched = function() {
      schedule:list()
    }
    hasMessages = function(rumors) {
      stuff = rumors.klog("IN HASMESSAGES")
      gotSome = rumors.filter(function(v,k) {
        v.length() > 0
      })
      gotSome.length() > 0
    }

    findRumorToSend = function(peer_to_check) {
      getReadings().map(function(messages,peerID)
      {
        candidates = messages.filter(function(message,sequence)
        {
          getPeerSeen(){peer_to_check}{peerID}.defaultsTo(-1) < sequence.decode()
        })
        candidates
      })
    }
    makeSeen = function() {
      boom = ent:allReadings.map(function(v,k) {
        v.keys().length()-1
        })
      returnthing = boom.klog("jere")
      returnthing
    }
    getReadings = function() {
      ent:allReadings
    }
  }




//SEENS

  rule send_seen {
    select when node send_seen
    pre {
      seen_message = makeSeen()
    }
    always {
      ent:lastSent := seen_message.klog("last sent: ")
      raise wrangler event "send_event_on_subs" attributes {
        "domain":"gossip",
        "type":"hear_seen",
        "Rx_role":"node",
        "attrs":{
          "seen":seen_message,
          "id":ent:myID
        }
      }
    }
  }

  rule receive_seen {
    select when gossip hear_seen
    pre {
      message = event:attr("seen").klog("message: = ")
      id = event:attr("id").klog("id: = ")
      running = ent:state.defaultsTo("on") == "on"
    }
    if running then noop();
    fired {
      ent:peerSeen := ent:peerSeen.defaultsTo({}).put(id, message).klog("peer seen")
    }
  }


  rule power_control {
    select when node power
    pre {
      state = event:attr("state").defaultsTo("on")
    }
    if state == "on" then noop();
    fired {
      ent:state := "on"
    } else {
      ent:state := "off"
    }
  }


//RUMORS
  rule receive_rumor {
    select when gossip rumor
    foreach event:attr("rumors").values() setting(x)
      foreach x.values() setting(message)
        pre {
          seq = message{"sequence"}
          seq_num = seq.sprintf("%d")
          id = message{"SensorID"}
          created = ent:allReadings{id}
          next = (created) => created.put(seq_num, message) | {}.put(seq_num, message)
          running = ent:state.defaultsTo("on") == "on"
        }
        if running then noop();
        fired {
          ent:allReadings := ent:allReadings.defaultsTo({}).put(id, next)
        }
  }

  /* rule send_rumor {
    select when gossip send_rumor
    pre {
      the_eci = event:attr("eci")
      message = event:attr("rumor")
      peerID = event:attr("id")
    }
    event:send(
     { "eci": the_eci,
       "eid": "anything", // can be anything, used for correlation
       "domain": "gossip", "type": "rumor",
       "attrs": {
         "rumor":message,
         "id":ent:myID
       }
     })
  } */

  rule make_rumor {
    select when node make_rumor
    pre {
      peerToSend = getPeers()[random:integer(getPeers().length()-1)]
      rumors = findRumorToSend(peerToSend{"id"}).klog("RUMORS TO SEND")
      eci = peerToSend{"Tx"}
      sendable = hasMessages(rumors)
      thing = peerToSend.klog("This is the peer to send to")
    }
    if sendable then event:send(
     { "eci": eci,
       "eid": "anything", // can be anything, used for correlation
       "domain": "gossip", "type": "rumor",
       "attrs": {
         "rumors":rumors,
         "id":ent:myID
       }
     })
    fired {
      ent:dummy := "made it".klog("sendable")
      raise node event "update_seen" attributes {"rumors": rumors, "recipient":peerToSend{"id"}}
    }
  }

  rule updateSeen {
    select when node update_seen
    pre {
      rumors = event:attr("rumors")
      rec_id = event:attr("recipient")
      /* newSeen = makeSeenHarder(rumors, rec_id) */
    }
    /* if doRumor then noop(); */
  }



  rule gossip_heartbeat {
    select when gossip heartbeat
    pre {
      a = random:integer(1)
      doRumor = (a == 0)
    }
    if doRumor then noop();
    fired {
      raise node event "make_rumor"
    }
    else {
      raise node event "send_seen"
    }
  }

  /* rule decide_rumor {
    select when node rumor_helper
    pre {
      a = random:integer(1)
      doNewRumor = (a == 0)
    }
    if doNewRumor then noop();
    fired {
      raise node event "new_rumor"
    }
    else {
      raise node event "make_rumor"
    }
  } */

  rule new_rumor {
    select when node new_rumor
    pre {
      message = makeRumor()
      temp_rumor = {}.put("temp", {}.put("temp", message)).klog("new rumor")
    }
    always {
      ent:curSeq := ent:curSeq + 1
      raise gossip event "rumor" attributes {"rumors": temp_rumor}
    }
  }



  //scheduled stuff
  rule change_schedule {
    select when sched change
    pre {
      period = event:attr("period").as("Number")
    }
    always {
      schedule gossip event "heartbeat"
          repeat << */#{period} * * * * * >>  attributes {} setting(id);
      ent:schedID := id
    }
  }

  rule delete_schedule {
    select when sched delete
    schedule:remove(ent:schedID)
  }









  /* always {
    ent:curSeq := ent:curSeq + 1
  } */
  /* foreach ent:peers setting(x)
  pre {
    the_eci = x{"Tx"}
    message = makeRumor()
    peerID = x{"id"}
  } */





  rule add_peer {
    select when node add_peer
    pre {
      peerID = event:attr("id")
      tx = event:attr("Tx")
      newPeer = {}
      newPeer1 = newPeer.put("id", peerID)
      newPeer2 = newPeer1.put("Tx", tx)
      newPeer3 = newPeer2.put("seen", {})
    }
    always {
      ent:peers := ent:peers.append(newPeer3)
    }
  }


  rule reset_node {
    select when sensor reset
    pre {
      here = random:uuid()
      temp = here.klog("BOOMER")
    }
    always {
      ent:state := "ok"
      ent:peers := []
      ent:peerSeen := {}
    }
  }








  rule inialize_ruleset {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    always {
      ent:myID := random:uuid()
      ent:curSeq := 0
      ent:peers := []
      ent:allReadings := {}
    }
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
        "name":"node", "channel_type":"subscription",
        "their_ID":ent:myID
      }
    })
  }

  rule node_subscription {
    select when node make_a_friend
    pre {
      theOtherRx = event:attr("otherRx")
    }
    event:send({"eci":theOtherRx,
      "domain":"wrangler", "name":"subscription",
      "attrs": {
        "wellKnown_Tx":subs:wellKnown_Rx(){"id"},
        "Rx_role":"node", "Tx_role":"node",
        "name":"node", "channel_type":"subscription",
        "their_ID":ent:myID
      }
    })
  }

  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      my_role = event:attr("Rx_role")
      their_role = event:attr("Tx_role")
    }
    if their_role=="node" then noop()
    fired {
      raise wrangler event "pending_subscription_approval"
        attributes event:attrs
      ent:subscriptionTx := event:attr("Tx")
      /* ent:peers := ent:peers.put(event:attr("their_ID"), {}) */
    } else {
      raise wrangler event "inbound_rejection"
        attributes event:attrs
    }
  }

  /* rule update_profile {
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
  } */
}
