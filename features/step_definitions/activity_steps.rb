Given /^I have loaded activity 30051790$/ do
  @gc = GarminConnectr.new
  @activity = @gc.load_activity( :id => 30051790 )
end

Then /^the ([\w_]+) should be "([^"]*)"$/ do |field, value|
  value = value.to_i if field.to_s.match(/count/i)
  @activity.send( field ).should == value
end

Then /^the ([\w_]+) for split ([\d\w]+) should be "([^\"]*)"$/ do |field, split, value|
  if split == 'summary'
    @activity.split_summary.send( field ).should == value  
  else
    @activity.splits[ split.to_i - 1 ].send( field ).should == value
  end
end