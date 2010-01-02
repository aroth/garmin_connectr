require '../lib/garmin_connectr.rb'

activity_id = 21450277

gc = GarminConnectr.new
activity = gc.load( activity_id )

puts activity.name
puts "  Activity : #{ activity.activity }"
puts "  Distance : #{ activity.distance }"
puts "  Start    : #{ activity.start_time }"
puts "  Avg HR   : #{ activity.avg_hr }"
puts "  Splits   : #{ activity.splits.count }"

activity.splits.each do |split|
  puts "\t#{ split['split'] } : Distance = #{ split['distance'] }"
end
