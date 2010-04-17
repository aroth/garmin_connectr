Scenario: Load Activity List
  Given I have loaded the activity list for username USERNAME with password PASSWORD
  Then the activity list should contain some activities
  And the first activity should have a name
  And the first activity should have a distance
  And the first activity should have a activity_type