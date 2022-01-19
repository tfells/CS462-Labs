ruleset test {
  meta {
    use module org.twilio.sdk alias sdk
      with
        apiKey = meta:rulesetConfig{"api_key"}
        sessionID = meta:rulesetConfig{"session_id"}
    shares __testing, getMessages 
  }
  global {
    getMessages = function(page, to, from) {
      sdk:getMessages(page, to, from)
    }

    __testing = {
          "queries": [{"name": "getMessages", "args":["to", "from", "page"]}],
          "events": [
              {"domain": "message", "name": "send_message", "attrs": ["to", "from", "message"]}
          ]
    }
  }

  rule send_message {
    select when message send_message
      
    pre {
      to = event:attrs{"to"}
      from = event:attrs{"from"}
      bodyText = event:attrs{"message"}
      valid = true
    }
    if valid then sdk:sendMessage(to, from, bodyText)
  }
}
