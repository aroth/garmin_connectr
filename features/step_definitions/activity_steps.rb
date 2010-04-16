Given /^I have loaded activity 30051790$/ do
  @gc = GarminConnectr.new
  @activity = @gc.load( 30051790 )
end

Then /^the ([\w_]+) should be "([^"]*)"$/ do |field, value|
  @activity.send( field ).should == value
end

Then /^the ([\w_]+) for split ([\d\w]+) should be "([^\"]*)"$/ do |field, split, value|
  @activity.splits[ split.to_s ][ field ].should == value
end