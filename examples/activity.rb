require '../lib/garmin_connectr.rb'

activity_id = 21450277

gc = GarminConnectr.new
activity = gc.load_activity( :id => activity_id )

puts activity.name
puts "  Activity : #{ activity.activity_type }"
puts "  Distance : #{ activity.distance }"
puts "  Start    : #{ activity.timestamp }"
puts "  Splits   : #{ activity.split_count }"

activity.splits.each do |split|
  puts "\t#{ split.split } : Distance = #{ split.distance }"
end
