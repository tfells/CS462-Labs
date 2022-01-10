ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    shares hello
    shares monkey, monkey2
  }

  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    monkey = function(name) {
      msg = "Hello " + (name || "Monkey");
      msg
    }
    monkey2 = function(name) {
      msg = "Hello " + ((name) => name | "Monkey");
      msg
    }
  }
   
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }

  rule hello_world2 {
    select when echo monkey
    send_directive("say", {"something": "Hello Monkey"})
  }
   
  rule hello_world3 {
    select when echo monkey2
    send_directive("say", {"something": "Hello with terntiary operater"})
  }
}
