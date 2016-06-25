require "socket"

=begin
=end
class ChatClient
	def initialize(connection)
		#Client keeps a local instance of connection
		@connection = connection

		#Initialze thread arrays to nil
		@requests = nil
		@responses = nil

		#Begin listening for incoming messages
		listen

		#Begin sending messages as requested
		send_message

		#join threads
		@requests.join
		@responses.join
	end

	def colorize(color_code)
    	"\e[#{color_code}m#{self}\e[0m"
  	end

	#send a message to the connection to be
	#propagated to each client
	def send_message
		puts "Enter a username"
		@requests = Thread.new do
			loop do
				#Get the message to send
				msg = $stdin.gets.chomp

				#Send to connection and prop.
        		@connection.puts(msg)
			end
		end
	end

	def listen
		@responses = Thread.new do 
			loop do
				#Get any messages from the connection
				message = @connection.gets.chomp

				#Print the message
        		print_message(message)
			end
		end
	end

	private

	#Parse a message and display it
	def print_message(message)
		#split string at the comma
		message_array = message.split("^|")

		print "#{message_array.first.blue}"

		unless message_array.length == 1
			print ": "
			
			#check for any mentions to highlight
			message_array.last.split(" ").each do |word|
				if word.start_with?('@')
					print "#{word.pink} "
				else
					print "#{word} "
				end
			end
		end
		puts ""
	end
end

=begin
A simple monkeypatch to the string class.
Adds colored output functions
=end	
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end

connection = TCPSocket.open("localhost", 3000)
ChatClient.new(connection)