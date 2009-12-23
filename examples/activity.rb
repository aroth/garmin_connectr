require '../lib/garmin_connectr.rb'

activity_id = 20733252

gc = GarminConnectr.new
activity = gc.load( activity_id )

puts activity.name
puts "  Activity : #{ activity.activity }"
puts "  Distance : #{ activity.distance }"
puts "  Start    : #{ activity.start_time }\n\n"