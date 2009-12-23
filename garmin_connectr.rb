require 'rubygems'
require 'nokogiri'
require 'open-uri'

class GarminConnectr
  
  attr_reader :name, :url, :device
  attr_reader :start_time, :start_time_str, :activity, :event, :time, :distance, :calories
  
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
    
    ## Tabbed Fields
    fields = []
    fields << ['Avg Speed', 'Max Speed', 'Elevation Gain', 'Elevation Loss', 'Min Elevation', 'Max Elevation']
    fields << ['Avg HR', 'Max HR', 'Avg Bike Cadence', 'Max Bike Cadence', 'Avg Temperature', 'Min Temperature']
    fields << ['Max Temperature', 'Avg Pace', 'Best Pace']
    fields.flatten!
    
    fields.each do |field|
      name = field.downcase.gsub(' ','_')
      (class << self; self; end).class_eval do
        define_method name do
          self.send :tab_data, field
        end
      end
    end
    
  end
  
  private
  
  def tab_data( field_label )
    field_label += ":" unless field_label.match(/:$/)
    @doc.css('.label').to_a.delete_if { |e| e.inner_html != field_label }.first.parent.children.search('.field').inner_html rescue nil
  end
  
  def create_method( name, value )
    class << self
      self.send( :define_method, name ){ "a" }
    end
  end
  
end