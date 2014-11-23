require_relative "rabbitmixin"

puts "starting server process"

conn = Bunny.new
conn.start

ch   = conn.create_channel

begin
  server = RabbitServer.new(ch)
  puts " [x] Awaiting RPC requests"
  server.start("rpc_queue")
rescue Interrupt => _
  ch.close
  conn.close
end
