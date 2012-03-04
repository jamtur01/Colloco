require 'colloco/util'
require 'sinatra'
require 'data_mapper'

module Colloco
  class Application < Sinatra::Base

    extend Colloco::Util

    configure do
      load_configuration("config/config.yml", "APP_CONFIG")
    end

    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')
    DataMapper.setup(:default, "sqlite3:db/colloco.db")
    disable :show_exceptions

    class Maps
      include DataMapper::Resource

      property :id, Serial
      property :title, String, :length => 250, :key => true
      property :maker, String, :key => true
      property :date, String, :key => true
      property :price, String
      property :source, String
      property :created_at, DateTime

      validates_presence_of :title
    end

    DataMapper.finalize
    DataMapper.auto_upgrade!

    before do
      @app_name = "Colloco - Manage your map collection"
    end

    get '/' do
      protected!
      @maps = Maps.all(:order => [ :id.desc ])
      flash_message(params[:m])
      erb :index
    end

    get '/map/:id' do |id|
      @map = Maps.first(:id => params[:id])
      erb :map
    end

    get '/add' do
      protected!
      flash_message(params[:m])
      erb :add
    end

    post '/create' do
      redirect "/?m=blank" if params[:title].empty?

      if Maps.count(:conditions => { :title => params[:title] }) > 0
        redirect "/?m=map_taken"
      end

      @map = Maps.new(:title      => params[:title],
                      :maker      => params[:maker],
                      :date       => params[:date],
                      :price      => params[:price],
                      :source     => params[:source],
                      :created_at => Time.now)

      if @map.save
        redirect "/?m=success"
      else
        redirect "/?m=invalid"
      end
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
          csv << [map.title, map.maker, map.date, map.price, map.source]
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

      def cycle
        %w{even odd}[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

      CYCLE = %w{even odd}

      def cycle_fully_sick
        CYCLE[@_cycle = ((@_cycle || -1) + 1) % 2]
      end

      def flash_message(message)
        case message
        when "blank"
          @notice = "You need to specify a title."
        when "map_taken"
          @notice = "You've already added a map with that title."
        when "success"
          @success = "Thank you! New map added!"
        else ""
        end
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
