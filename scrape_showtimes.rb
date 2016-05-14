# encoding: UTF-8

require "selenium-webdriver"
require "pry"
require "chronic"
require "active_record"
require "sqlite3"

ActiveRecord::Base.logger = Logger.new(STDERR)
# Delete any existing database
begin
  FileUtils.rm("./titan.sqlite3")
rescue Errno::ENOENT
end
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "./titan.sqlite3")

ActiveRecord::Schema.define do
  create_table :movies do |table|
    table.column :name, :string
  end

  create_table :theaters do |table|
    table.column :name, :string
    table.column :district, :string
    table.column :brand_id, :integer
  end

  create_table :brands do |table|
    table.column :name, :string
  end

  create_table :screenings do |table|
    table.column :screening_at, :datetime
    table.column :movie_id, :integer
    table.column :theater_id, :integer
  end
end

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
end

class ShowtimesPage
  attr_reader :movie_name
  attr_reader :url

  def initialize(movie_name, movie_showtime_url)
    @movie_name = movie_name
    @url = movie_showtime_url
  end

  def scrape
    driver = $driver
    date = $date

    driver.navigate.to(url)

    25.times do |i|
      scroll_position = 5000 * i
      driver.execute_script("window.scrollTo(0, #{scroll_position})")
      sleep 2 # Wait for some time for the showtime data to be fetched
      begin
        driver.find_element(:xpath, %Q(//div[@date="#{date}"]))
      rescue Selenium::WebDriver::Error::NoSuchElementError
        next
      end
      break
    end

    showtimes_wrapper_element = driver.find_element(:id => "wrap-time")
    showtime_elements = showtimes_wrapper_element.find_elements(:xpath, %Q(//div[@class="item-session future clearfix"]))

    movie = Movie.create!(name: movie_name)

    showtime_elements.each do |showtime_element|
      showtime_info = showtime_element.text.split("\n") # Sun, 21:00, 2D, LOTTE | D.2, Cantavil An Phu, English Vietnamese Sub, No booking

      day = showtime_info[0] # Sun
      time = showtime_info[1] # 21:00
      screening_at = Chronic.parse("#{day}, #{time}").utc

      theater_brand_and_district = showtime_info[3] # LOTTE | D.2
      theater_brand, theater_district = theater_brand_and_district.split(" | ")
      theater_name = showtime_info[4]

      brand = Brand.find_or_create_by(name: theater_brand)
      theater = Theater.find_or_create_by(name: theater_name) # Assuming that each theater has a unique name for now
      theater.district = theater_district
      theater.brand = brand
      theater.save!

      screening = Screening.new
      screening.screening_at = screening_at
      screening.movie = movie
      screening.theater = theater
      screening.save!
    end
  end
end

movie_name_movie_showtime_url_mapping = {
  "Angry Birds" => "http://dimovie.vn/en/sessions?fid=20601",
  # "Captain America: Civil War" => "http://dimovie.vn/en/sessions?fid=18882",
  # "Ratchet & Clank" => "http://dimovie.vn/en/sessions?fid=23456",
  # "Tracer" => "http://dimovie.vn/en/sessions?fid=24525",
  # "The Jungle Book" => "http://dimovie.vn/en/sessions?fid=21551",
  "Lật Mặt" => "http://dimovie.vn/en/sessions?fid=18302"
}
driver = Selenium::WebDriver.for(:firefox)
$driver = driver
driver.manage.window.maximize
$date = "2016-05-17" # Tuesday
movie_name_movie_showtime_url_mapping.each do |movie_name, movie_showtime_url|
  ShowtimesPage.new(movie_name, movie_showtime_url).scrape
end
driver.quit
