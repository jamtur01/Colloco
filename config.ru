$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'colloco'

use Rack::ShowExceptions

run Colloco::Application.new
