require 'rubygems'
require 'msgpack/rpc'
require 'digest/sha1'

class Client
	def initialize(svr, balancers)
		@balancers = balancers
		@svr = svr
	end

	def get(key)
		puts "get: '#{key}'"

		ss = @svr.get_session(*balancer_for(key))

		as = MessagePack::RPC::AsyncResult.new
		ss.callback(:get, key) {|err, res|
			as.result(res, err)
		}

		as
	end

	def set(key, val)
		puts "set: '#{key}' = '#{val}'"

		ss = @svr.get_session(*balancer_for(key))

		as = MessagePack::RPC::AsyncResult.new
		ss.callback(:set, key, val) {|err, res|
			as.result(res, err)
		}

		as
	end

	private
	def balancer_for(key)
		@balancers[ Digest::SHA1.digest(key).unpack('Q')[0] % @balancers.size ]
	end
end

if ARGV.size <= 1
	puts "usage: #{$0} <port> <balancer host:port> ..."
	exit 1
end

port = ARGV.shift.to_i

balancers = ARGV.map {|node|
	bhost, bport = node.split(':',2)
	[bhost, bport.to_i]
}

svr = MessagePack::RPC::Server.new
svr.listen '0.0.0.0', port, Client.new(svr, balancers)
svr.run

