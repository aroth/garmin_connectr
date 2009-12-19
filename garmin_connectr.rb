require 'rubygems'
require 'nokogiri'
require 'open-uri'

class GarminConnectr
  
  attr_reader :name, :url, :device
  attr_reader :start_time, :start_time_str
  attr_reader :activity, :event, :time, :distance, :calories
  attr_reader :avg_speed, :max_speed
  attr_reader :elevation_gain, :elevation_loss, :min_elevation, :max_elevation
  attr_reader :avg_heartrate, :max_heartrate
  attr_reader :avg_cadence, :max_cadence
  attr_reader :avg_temperature, :min_temperature, :max_temperature
  
  def initialize( id )
    @id = id
    self.fetch
  end
  
  def fetch
    @doc = Nokogiri::HTML(open("http://connect.garmin.com/activity/#{ @id }"))
    
    ## Name & URL
    @name = @doc.search('#activityName').inner_html
    @url = "http://connect.garmin.com/activity/#{ @id }"
    @device = @doc.search('.additionalInfoContent span').inner_html.gsub('Device: ','')
    
    ## Start 
    @start_time_str = @doc.search('#activityStartDate').children[0].to_s.gsub(/[\n]+/,'')
    @start_time = DateTime.parse( @start_time_str )

    ## Summary Fields
    @activity = @doc.search('#activityTypeValue').inner_html.gsub(/[\n]+/,'')
    @event = @doc.search('#eventTypeValue').inner_html.gsub(/[\n]+/,'')
    @time = @doc.css('#summaryTotalTime')[0].parent.children.search('.summaryField').inner_html
    @distance = @doc.css('#summaryDistance')[0].parent.children.search('.summaryField').inner_html
    @calories = @doc.css('#summaryCalories')[0].parent.children.search('.summaryField').inner_html
    
    ## Timing Fields
    @avg_speed = tab_data('Avg Speed')
    @max_speed = tab_data('Max Speed')
    
    ## Elevation Fields
    @elevation_gain = tab_data('Elevation Gain')
    @elevation_loss = tab_data('Elevation Loss')
    @min_elevation = tab_data('Min Elevation')
    @max_elevation = tab_data('Max Elevation')
    
    ## Heart Rate Fields
    @avg_heartrate = tab_data('Avg HR')
    @max_heartrate = tab_data('Max HR')
    
    ## Cadence Fields
    @avg_cadence = tab_data('Avg Bike Cadence')
    @max_cadence = tab_data('Max Bike Cadence')
    
    ## Temperature Fields
    @avg_temperature = tab_data('Avg Temperature')
    @min_temperature = tab_data('Min Temperature')
    @max_temperature = tab_data('Max Temperature')
    
    ## Power Fields
    # TODO: I don't have a PowerMeter yet...
  end
  
  private
  
  def tab_data( field_label )
    field_label += ":" unless field_label.match(/:$/)
    @doc.css('.label').to_a.delete_if { |e| e.inner_html != field_label }.first.parent.children.search('.field').inner_html
  end
  
end