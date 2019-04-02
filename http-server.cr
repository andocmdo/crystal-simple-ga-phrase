# A very basic HTTP server
require "http/server"

count = 0

spawn do
  10000.times do
    sleep 1.second 
    count += 1
  end
end


server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print "Hello world, count is: #{count}!"
end

puts "Listening on http://127.0.0.1:8080"
server.listen(8080)
