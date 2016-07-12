=begin
Weston Dransfield
CS 460
Chat Client
=end

require "socket"
require "io/wait"

class ChatClient
	def initialize(connection)
		#Client keeps a local instance of connection
		@connection = connection
		@username = ""
		@draft = ""

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


	def get_char
		state = `stty -g`
		`stty raw -echo -icanon isig`

		STDIN.getc.chr
	ensure
		`stty #{state}`
	end

	#colorize strings
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
				#msg = $stdin.gets.chomp
				msg = @draft

				while (chr = get_char).ord != 13
					# If the user backspaced
					if chr.ord == 127 && msg != ""
						#Pop off the last letter
						msg = msg[0...-1]
						print "\r\033[K"
						$stdout.flush
						print "#{@username}: #{msg}" 
						@draft = msg
					else
						print chr
						msg += chr
						@draft = msg
					end
				end

				#Set the username
				@username = msg if @username.empty?

				#Send to connection and prop.
				@connection.puts(msg)

				@draft = ""

        		#Display a prompt
        		print "\n#{@username}: "

        		#Check for quit
				exit if msg == "\\quit"
        	end
        end
    end

    def stop
    	puts "stopped?"
    end

    def listen
    	@responses = Thread.new do 
    		loop do
				#Get any messages from the connection
				message = @connection.gets.chomp

				#Go to start of line
				print "\r\033[K"
				$stdout.flush
				#Print the message
				print_message(message.strip)

        		#Remove white space
        		(message.length + 1).times do
        			print "\b"
        		end

        		#Display a prompt
        		print "#{@username}: #{@draft}"
        	end
        end
    end

    private

	#Notify the user
	def notify
		print "\a"
	end

	#Parse a message and display it
	def print_message(message)
		#split string at the comma
		message_array = message.split("^|")

		print "#{message_array.first.blue}"

		unless message_array.length == 1
			print ": "
			
			#check for any mentions to highlight
			message_array.last.split(" ").each do |word|
				if (word.start_with?('@') && word.downcase.include?(@username.downcase)) || word.downcase.include?("yall")
					print "#{word.yellow} "
					notify
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

#Establish the connection and start the client
connection = TCPSocket.open("localhost", 3000)
chat_client = ChatClient.new(connection)