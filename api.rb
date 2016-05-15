require "sinatra"
require "pry"
require "wit"
require "chronic"
require "yaml"
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "./titan.sqlite3")

class Movie < ActiveRecord::Base
end

class Brand < ActiveRecord::Base
end

class Theater < ActiveRecord::Base
  belongs_to :brand
end

class Screening < ActiveRecord::Base
  belongs_to :movie
  belongs_to :theater
end

class Movie < ActiveRecord::Base
  has_many :screenings
  has_many :theaters, through: :screenings
end

WIT_ACCESS_TOKEN = "QZJFZIMIS4UIL4H533E2KFEMX76JU4HV"

class WitResponse
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

class Session
  def initialize
    @session_hash = {}
    @session_hash = YAML.load_file(File.open(session_file_path)) if File.exist?(session_file_path)
  end

  def session_file_path
    "/tmp/jarvis_session.yml"
  end

  def [](key)
    @session_hash[key]
  end

  def []=(key, value)
    @session_hash[key] = value
    serialize_session_hash
  end

  def serialize_session_hash
    File.open(session_file_path, "w") { |session_file| session_file.write(@session_hash.to_yaml) }
  end

  def delete
    begin
      FileUtils.rm(session_file_path)
    rescue
    end
  end
end

class WitResponseHandler
  def handle_response(response)
    session = Session.new

    case response.intent
    when "greet"
      "Hi there!"
    when "tell_movie_name"
      session["movie_name"] = response.movie_name
      "That's a great choice! When do you want to see it?"
    when "tell_preferred_screening_time"
      session["preferred_screening_time"] = Chronic.parse(response.datetime).utc
      "Alright, I've booked a ticket for #{session['movie_name']} at that time. Have a great day!"

      movie = Movie.find_by_name(session["movie_name"])
      preferred_screening_time = session["preferred_screening_time"]
      screening = movie.screenings.where("screening_at > ?", preferred_screening_time).order(screening_at: :asc).first
      theater = screening.theater
      screening_at_in_vietnam_time = screening.screening_at + (7 * 3600)

      "Alright, I've booked a ticket for #{session['movie_name']} at #{theater.name} at #{screening_at_in_vietnam_time.strftime("%H:%M %p")}. Have a great day!"
    else
      "Sorry, I don't understand you :("
    end
  end
end

def wit_client
  return @wit_client if @wit_client

  actions = {
    :say => -> (session_id, context, msg) {
    },
    :merge => -> (session_id, context, entities, msg) {
    },
    :error => -> (session_id, context, error) {
    },
  }
  @wit_client = Wit.new(WIT_ACCESS_TOKEN, actions)
end

get "/reply" do
  begin
    message_text = params[:text]

    wit_response_hash = wit_client.message(message_text)
    wit_response = WitResponse.new(wit_response_hash)
    reply_text = WitResponseHandler.new.handle_response(wit_response)
  rescue => e
    puts e.message
    puts e.backtrace
    reply_text = "Oops! Something went wrong. Please type again."
  end

  # { reply: { text: reply_text } }.to_json
  { reply: reply_text }.to_json
end

post "/restart_conversation" do
  session = Session.new
  session.delete
end
