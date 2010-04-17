Given /^I have loaded the activity list for username ([\w]+) with password ([\w]+)$/ do |username, password|
  @gc = GarminConnectr.new
  @activities = @gc.load_activity_list( :username => username, :password => password )
end

Then /^the activity list should contain some activities$/ do
  @activities.size.should_not == 0
end

Then /^the first activity should have a ([\w]+)$/ do |field|
  @activities.first.send( field.to_sym ).should_not == nil
end