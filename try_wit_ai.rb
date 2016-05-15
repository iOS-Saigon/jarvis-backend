require "wit"
require "pry"
require "chronic"

access_token = "QZJFZIMIS4UIL4H533E2KFEMX76JU4HV"
actions = {
  :say => -> (session_id, context, msg) {
  },
  :merge => -> (session_id, context, entities, msg) {
  },
  :error => -> (session_id, context, error) {
  },
}
client = Wit.new(access_token, actions)

message = "I want to go to Iron Man"
response = client.message(message)

class Response
  attr_reader :response_hash

  def initialize(response_hash)
    @response_hash = response_hash
  end

  def intent
    response_hash["outcomes"].first["entities"]["intent"].first["value"]
  end

  def movie_name
    response_hash["outcomes"].first["entities"]["movie_name"].first["value"]
  end

  def datetime
    response_hash["outcomes"].first["entities"]["datetime"].first["value"]
  end
end

$session = {}

class ResponseHandler
  def handle_response(response)
    case response.intent
    when "tell_movie_name"
      $session[:movie_name] = response.movie_name
      puts "Jarvis: That's a great choice! What do you want to see it?"
    when "tell_preferred_screening_time"
      $session[:preferred_screening_time] = Chronic.parse(response.datetime)
      puts "Jarvis: Alright, I've booked a ticket for #{$session[:movie_name]} at that time. Have a great day!"
    else
      puts "Jarvis: Sorry, I don't understand you :("
    end
  end
end

messages = [
  "I'd like to see Iron Man",
  "At 7 am today"
]

puts "Jarvis: Hi, I'm Jarvis. What movie would you like to see?"
messages.each do |message|
  puts message
  response_hash = client.message(message)
  response = Response.new(response_hash)
  ResponseHandler.new.handle_response(response)
end
