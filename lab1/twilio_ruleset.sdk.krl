ruleset org.twilio.sdk {
  meta {
    configure using
      apiKey = ""
      sessionID = ""
    provides getMessages, sendMessage 
  }
  global {
    base_url = "https://api.twilio.com/2010-04-01/Accounts/AC8f01bf2a0c269c56b9b9750c8f248442/Messages"
    authString = {"password":apiKey,"username":sessionID}


    getMessages = function(page, to, from) {
      page_temp = ((page) => page | "50");
        page_num = page_temp.as("Number")
        valid_page = 0 <= page_num && page_num <= 1000000
      qstring = {"PageSize":page_num,"To":to,"From":from}.klog("qs");
      response = http:get(<<#{base_url}.json>>, auth=authString, qs=qstring)
      response{"content"}.decode()
    }
    sendMessage = defaction(to, from, bodyText) {
      bodyJson = {"Body":bodyText,"To":to,"From":from}
      http:post(<<#{base_url}.json>>, auth=authString, form=bodyJson) setting(response)
      return response
    }
  }
}
