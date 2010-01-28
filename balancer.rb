require 'rubygems'
require 'msgpack/rpc'

class Balancer
	def initialize(svr)
		@dbs = []
		@svr = svr
	end

	def set(key, val)
		puts "get: '#{key}'"

		@dbs.each {|node|
			ss = @svr.get_session(*node)
			ss.callback(:repl, key, val) {|err, res|
				# FIXME retry
			}
		}

		# FIXME asynchronous, no-error
		nil
	end

	def get(key)
		puts "get: '#{key}'"

		@rr ||= 0
		node = @dbs[ (@rr += 1) % @dbs.size ]  # FIXME round-robin
		ss = @svr.get_session(*node)

		as = MessagePack::RPC::AsyncResult.new
		ss.callback(:get, key) {|err, res|
			as.result(res, err)
		}

		as
	end

	def add_node(host, port)
		@dbs.push [host, port]
		nil
	end

	def get_nodes
		@dbs
	end
end

if ARGV.size != 1
	puts "usage: #{$0} <port>"
	exit 1
end

port = ARGV.shift.to_i

svr = MessagePack::RPC::Server.new
svr.listen '0.0.0.0', port, Balancer.new(svr)
svr.run

