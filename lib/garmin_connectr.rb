require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'fastercsv'

class GarminConnectr
  
  attr_reader :activity_list
  
  def initialize
    @activity_list = []
  end
  
  ## Load a specific Garmin Connect activity. See GarminConnectActivity rdoc for more information.
  def load( activity_id )
    activity = GarminConnectActivity.new( activity_id )
    activity.load!
  end
  
  ## Returns an array of GarminActivity objects. 
  ##
  ## Options:
  ##    :preload [true/false] - Automatically fetch additional activity data for each activity returned (slower)
  ##    :limit - Limit the number of activites returned (default: 50)
  def activities( username, password, opts={} )
    @activity_list = []
    limit = opts[:limit] || 50
    
    agent = WWW::Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
    page = agent.get('http://connect.garmin.com/signin')
    form = page.form('login')
    form.send('login:loginUsernameField', username)
    form.send('login:password', password)
    form.submit
    
    page = agent.get('http://connect.garmin.com/activities')

    doc = Nokogiri::HTML( page.body )
    activities = doc.search('.activityNameLink')
    activities[0, limit].each do |act|
      name = act.search('span').inner_html
      act[:href].match(/\/([\d]+)$/)
      aid = $1
      
      activity = GarminConnectActivity.new( aid, name )
      activity.load! if opts[:preload]
      @activity_list << activity
    end
    @activity_list
  end
  
end

class GarminConnectActivity

  attr_reader :activity_id, :loaded, :name, :url, :device, :start_time, :activity, :event, :time, :distance, :calories
  attr_reader :avg_speed, :max_speed, :avg_power, :max_power, :elevation_gain, :elevation_loss, :min_elevation, :max_elevation, :avg_hr, :max_hr, :avg_bike_cadence, :max_bike_cadence, :avg_temperature, :min_temperature, :max_temperature, :avg_pace, :best_pace
  
  FIELDS = ['Avg Speed', 'Max Speed', 'Avg Power', 'Max Power', 'Elevation Gain', 'Elevation Loss', 'Min Elevation', 'Max Elevation', 'Avg HR', 'Max HR', 'Avg Bike Cadence', 'Max Bike Cadence', 'Avg Temperature', 'Min Temperature', 'Max Temperature', 'Avg Pace', 'Best Pace']
  
  def initialize( activity_id, name=nil )
    @activity_id = activity_id
    @name = name unless name.nil?
    @loaded = false
    @fields = ['name', 'url', 'device', 'start_time']
    @splits = []
    @split_summary = {}
  end
  
  ## Fetch activity details. This will happen automatically if using GarminConnect#load. You will have
  ## call load! explicity on the activities returned by GarminConnect#activities unless the :preload option is set to true.
  def load!
    @doc = Nokogiri::HTML(open("http://connect.garmin.com/activity/#{ @activity_id }"))
    @name = @doc.search('#activityName').inner_html
    @url = "http://connect.garmin.com/activity/#{ @activity_id }"
    @device = @doc.search('.additionalInfoContent span').inner_html.gsub('Device: ','')
    @start_time = @doc.search('#activityStartDate').children[0].to_s.gsub(/[\n]+/,'')
    @loaded = true

    # Summary Fields (TODO: clean up)
    @activity = @doc.search('#activityTypeValue').inner_html.gsub(/[\n]+/,'').strip rescue nil
    @event = @doc.search('#eventTypeValue').inner_html.gsub(/[\n]+/,'').strip rescue nil
    @time = @doc.css('#summaryTotalTime')[0].parent.children.search('.summaryField').inner_html.strip rescue nil
    @distance = @doc.css('#summaryDistance')[0].parent.children.search('.summaryField').inner_html.strip rescue nil
    @calories = @doc.css('#summaryCalories')[0].parent.children.search('.summaryField').inner_html.strip rescue nil
        
    # Tabbed Fields
    FIELDS.each do |field|
      name = field.downcase.gsub(' ','_')
      self.instance_variable_set("@#{ name }", self.send( :tab_data, field ) )
    end

    # Splits - parse CSV
    @doc = open("http://connect.garmin.com/csvExporter/#{ @activity_id }.csv")
    @splits = []
    @split_summary  = {}
    
    @keys = []
    @csv = FasterCSV.parse( @doc.read )
    @csv[0].each do |key|
      @keys.push key.downcase.gsub(' ','_') if key.is_a?(String)
    end
    ## Data Rows
    @csv[1, @csv.length - 2].each_with_index do |row, index|
      split = {}
      @keys.each_with_index do |key, key_index|
        split[ key ] = row[ key_index ]
      end
      @splits << split
    end
    ## Summary Row
    @keys.each_with_index do |key, key_index|
      @split_summary[ key ] = @csv.last[ key_index ]
    end
    
    self
  end

  ## Returns an array of hashes detailing activity splits (laps). Attributes may include:
  ##
  ##  split
  ##  time
  ##  distance
  ##  elevation_gain
  ##  elevation_loss
  ##  avg_speed
  ##  max_speed
  ##  avg_hr
  ##  max_hr
  ##  avg_bike_cadence
  ##  max_bike_cadence
  ##  calories
  ##  avg_temp
  ##  max_power
  ##  avg_power
  def splits
    @splits
  end
  
  ## Returns a hash of activity splits/laps summary. See splits rdoc for possible attributes.
  def split_summary
    @split_summary
  end

  private
  
  def tab_data( label )
    label += ":" unless label.match(/:$/)
    @doc.css('.label').to_a.delete_if { |e| e.inner_html != label }.first.parent.children.search('.field').inner_html.strip rescue nil
  end
    
end