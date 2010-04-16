require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fastercsv'

class GarminConnectr
  def initialize
    @activity_list = []
  end
  
  def load( activity_id )
    activity = GarminConnectActivity.new( activity_id )
    activity.load!
  end
  
  def activities( username, password )
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
  
  attr_reader :activity_id, :data, :fields, :splits
  
  def initialize( activity_id )
    @activity_id = activity_id
    @fields = [:name, :activity_type, :event_type, :timestamp, :embed]
  end
  
  def load!
    url = "http://connect.garmin.com/activity/#{ @activity_id }"
    doc = Nokogiri::HTML(open(url))
    
    # HR cell name manipulation
    ['bpm', 'pom', 'hrZones'].each do |hr|
      doc.css("##{ hr }Summary td").each do |e|
        e.inner_html = "Max HR #{ hr.upcase }:" if e.inner_html =~ /Max HR/i
        e.inner_html = "Avg HR #{ hr.upcase }:" if e.inner_html =~ /Avg HR/i
      end
    end
    
    @data = {
      :details => {
        :name => doc.css('#activityName').inner_html,
        :activity_type => doc.css('#activityTypeValue').inner_html.gsub(/[\n\t]+/,''),
        :event_type    => doc.css('#eventTypeValue').inner_html.gsub(/[\n\t]+/,''),
        :timestamp     => doc.css('#timestamp').inner_html.gsub(/[\n\t]+/,''),
        :embed         => doc.css('.detailsEmbedCode').attr('value')
      },
      :summaries => {
        :overall     => { :css => '#detailsOverallBox', :data => {} },
        :timing      => { :css => '#detailsTimingBox', :data => {} },
        :elevation   => { :css => '#detailsElevationBox', :data => {} },
        :heart_rate  => { :css => '#detailsHeartRateBox', :data => {} },
        :cadence     => { :css => '#detailsCadenceBox', :data => {} },
        :temperature => { :css => '#detailsTemperatureBox', :data => {} },
        :power       => { :css => '#detailsPowerBox', :data => {} }
      }
    }

    @data[:summaries].each do |k,v|
      doc.css("#{ v[:css] } td").each do |e|
        if e.inner_html =~ /:[ ]?$/
          key = e.inner_html.downcase.gsub(/ $/,'').gsub(/:/,'').gsub(' ','_').to_sym
          v[:data][key] = e.next.next.inner_html
          @fields.push(key)
        end
      end
    end

    ## Lap Count
    @data[:summaries][:overall][:data][:lap_count] = doc.css('.detailsLapsNumber')[0].inner_html

    ## Splits
    @doc = open("http://connect.garmin.com/csvExporter/#{ @activity_id }.csv")
    @splits = {}

    @keys = []
    @csv = FasterCSV.parse( @doc.read )
    @csv[0].each do |key|
      @keys.push key.downcase.gsub(' ','_') if key.is_a?(String)
    end
    ## Data Rows
    @csv[1, @csv.length-1].each_with_index do |row, index|
      split = { }
      
      name = ( index == @csv.length - 2 ? 'summary' : index + 1 ).to_s
      
      @splits[ name ] = {}
      @keys.each_with_index do |key, key_index|
        @splits[ name ][ key ] = row[ key_index ]
      end
    end

    self
  end
  
  def method_missing( name )
    @data[:details].each { |k1,v1| return v1 if k1.to_s == name.to_s }
    @data[:summaries].each { |k1,v1| v1[:data].each { |k2,v2| return v2 if k2.to_s == name.to_s } }
    nil
  end
  
end
