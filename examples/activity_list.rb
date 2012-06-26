require '../lib/garmin_connectr.rb'

username = 'garmin_connect_username'
password = 'garmin_connect_password'

gc = GarminConnectr.new
activities = gc.load_activity_list( :username => username, :password => password )

activities.each do |activity|
  puts "#{ activity.name }"
  activity.load!
  puts "  Activity : #{ activity.activity_type }"
  puts "  Distance : #{ activity.distance }"
  puts "  Start    : #{ activity.timestamp }\n\n"
end
