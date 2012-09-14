require 'version'
require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'yaml'

def load_configuration(file, name)
  if !File.exist?(file)
    puts "There's no configuration file at #{file}!"
    exit!
  end
  Colloco.const_set(name, YAML.load_file(file))
end

module Colloco
  class Application < Sinatra::Base

    enable :sessions

    register Sinatra::Flash
    helpers Sinatra::RedirectWithFlash

    configure do
      load_configuration("config/config.yml", "APP_CONFIG")
      set :session_secret, "My session secret"
    end

    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')
    DataMapper::Property::String.length(255)
    DataMapper.setup(:default, "sqlite3:db/colloco.db")
    disable :show_exceptions

    class Maps
      include DataMapper::Resource

      property :id, Serial
      property :title, String, :length => 250, :key => true
      property :maker, String, :key => true
      property :date, String, :key => true
      property :price, Integer
      property :source, String
      property :size, String
      property :notes, Text
      property :created_at, DateTime

      validates_presence_of :title
    end

    DataMapper.finalize
    DataMapper.auto_upgrade!

    before do
      @app_name = "Colloco"
    end

    get '/' do
      protected!
      @maps = Maps.all(:order => [ :id.asc ])
      @total = Maps.sum(:price)
      erb :index
    end

    get '/map/:id' do |id|
      @map = Maps.first(:id => params[:id])
      erb :edit
    end

    post '/map/:id' do
      map = Maps.get(params[:id],params[:title],params[:maker],params[:date])

      map.attributes = {
        :title      => params[:title],
        :maker      => params[:maker],
        :date       => params[:date],
        :price      => params[:price],
        :source     => params[:source],
        :size       => params[:size],
        :notes      => params[:notes],
      }

      if map.save
        redirect '/', :success => "Map #{params[:title]} updated." 
      else
        redirect back, :error => errors(map)
      end
    end

    get '/add' do
      protected!
      erb :add
    end

    post '/create' do
      redirect back, :error => 'You need to specify a title.' if params[:title].empty?

      if Maps.count(:conditions => { :title => params[:title] }) > 0
        redirect back, :error => "You already have a map called #{params[:title]}"
      end

      @map = Maps.new(:title      => params[:title],
                      :maker      => params[:maker],
                      :date       => params[:date],
                      :price      => params[:price],
                      :source     => params[:source],
                      :size       => params[:size],
                      :notes      => params[:notes],
                      :created_at => Time.now)

      if @map.save
        redirect '/', :success => "New map #{params[:title]} added."
      else
        redirect back, :error => errors(@map)
      end
    end

    get '/search'  do
       @results = Maps.all(:title.like => "%#{params[:query]}%") | Maps.all(:source.like => "%#{params[:query]}%") | Maps.all(:notes.like => "%#{params[:query]}%")
      erb :search
    end

    get '/download' do
      protected!
      @map_count = Maps.count
      erb :download
    end

    get '/download/csv' do
      protected!
      csv_content = FasterCSV.generate do |csv|
        maps = Maps.all(:order => [ :id.desc ])
        maps.each do |map|
          csv << [map.title, map.maker, map.date, map.source, map.size, map.notes, map.price]
        end
      end

      headers "Content-Disposition" => "attachment;filename=maps.csv",
              "Content-Type" => "text/csv"
      csv_content
    end

    error do
      @error = "Sorry there was a nasty error! Please let Operations know that: " + env['sinatra.error']
      erb :error
    end

    helpers do
      def errors(obj)
        tmp = []
        obj.errors.each do |e|
          tmp << e
        end
        tmp
      end

      def pluralize(count, singular, plural = nil)
        "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || singular.pluralize))
      end

      def testing?
        ENV['RACK_ENV'] == "test"
      end

      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Authentication Required")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        return true if testing?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [APP_CONFIG["admin_username"], APP_CONFIG["admin_password"]]
      end
    end
  end
end
