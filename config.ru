require_relative 'forum'

use Rack::MethodOverride

run Forum::Server