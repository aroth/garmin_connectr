require 'garmin_connectr'
g = GarminConnectr.new( 20733252 )

puts "NAME: #{ g.name }"
puts "URL: #{ g.url }"
puts "DEVICE: #{ g.device }"
puts "ACTIVITY: #{ g.activity }"
puts "DISTANCE: #{ g.distance }"
