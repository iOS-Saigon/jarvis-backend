require "selenium-webdriver"
require "pry"

driver = Selenium::WebDriver.for(:firefox)
driver.manage.window.maximize
url = "http://dimovie.vn/en/sessions?fid=18882"
driver.navigate.to(url)

date = "2016-05-17" # Tuesday
25.times do |i|
  scroll_position = 5000 * i
  # driver.execute_script("window.scrollTo(0, 1000);")
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

showtime_elements.each do |showtime_element|
  puts showtime_element.text.gsub("\n", ", ")
end

# binding.pry

driver.quit
