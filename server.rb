require "socket"

class ChatServer
	def initialize(ip, port)
		@server = TCPServer.open(ip, port)
    	@connections = Hash.new
    	@clients = Hash.new
    	@connections[:clients] = @clients
    	run
	end

	def propagate_messages(username, client)
		puts "listening to #{username}"
		loop do
			#Get the next message from the client
			message = client.gets.chomp

			puts ">> #{username} #{message}"

			#Propagate the message to all other connected clients
			@connections[:clients].each do |send_name, send_client|
				#Don't send the message to the sender
				unless send_name == username 
					#Send the message
					send_client.puts "#{username.to_s}^|#{message}"
				end
			end
		end
	end

	def run
		loop {
			#Start a thread for each client that connects
			Thread.start(@server.accept) do |client|
				#Read the username 
				#The username shouold be the first message sent
				username = client.gets.chomp.to_sym

				puts "Connected user: #{username}" 

				#Loop through each client and verify uniqueness
				@connections[:clients].each do |used_name, used_client|
					if username == used_name || client == used_client
						#let the user know the name is not unique
						client.puts "That username is already in use"

						#kill the thread
						Thread.kill self
					end
				end

				@connections[:clients][username] = client
				client.puts "Welcome #{username}! You are now connected."

				#Listen for messages to propagate
				propagate_messages(username, client)
			end
		}.join
	end
end

server = ChatServer.new("localhost", 3000)
