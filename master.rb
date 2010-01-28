require 'rubygems'
require 'msgpack/rpc'

class Master
	def initialize(svr)
		@hash = {}
		@svr = svr
	end

	def get(key)
		puts "get: '#{key}'"

		@hash[key]
	end

	def repl(key, val)
		puts "repl: '#{key}' = '#{val}'"

		@hash[key] = val
		nil
	end
end


if ARGV.size != 1
	puts "usage: #{$0} <port>"
	exit 1
end

port = ARGV.shift.to_i

svr = MessagePack::RPC::Server.new
svr.listen '0.0.0.0', port, Master.new(svr)
svr.run

