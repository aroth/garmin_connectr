require 'garmin_connectr'
g = GarminConnectr.new( 20874127 )

puts "NAME: #{ g.name }"
puts "URL: #{ g.url }"
puts "DEVICE: #{ g.device }"
puts "ACTIVITY: #{ g.activity }"
puts "DISTANCE: #{ g.distance }"
puts "TEMP: #{ g.avg_temperature } / #{ g.max_temperature }"
