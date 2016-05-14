require "selenium-webdriver"
require "pry"
require "chronic"
require "active_record"
require "sqlite3"

ActiveRecord::Base.logger = Logger.new(STDERR)
# Delete any existing database
begin
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

driver = Selenium::WebDriver.for(:firefox)
driver.manage.window.maximize
url = "http://dimovie.vn/en/sessions?fid=18882"
driver.navigate.to(url)

date = "2016-05-17" # Tuesday

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

movie_name = "Captain America: Civil War"
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

driver.quit
