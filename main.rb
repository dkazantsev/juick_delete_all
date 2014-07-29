require 'xmpp4r'
# require 'em-synchrony'

class JuickClient
  include Jabber

  @@juick_jid = 'juick@juick.com'

  def initialize(jid, password, nickname)
    @jid = JID.new(jid.strip)
    @password = password.strip
    @nickname = nickname.strip
  end

  def connect
    @connection = Client.new @jid
    @connection.connect
    @connection.auth @password
    @connection.send iamonline

    true
  rescue
    puts "Check you Jabber ID and it's password please"
    exit 1
  end

  def disconnect
    @connection.close
  end

  def say(text, output = false)
    message = Message.new @@juick_jid, text
    message.type = :chat

    @connection.send(message)

  rescue IOError
    # don't know why but I have to reconnect
    connect and retry
  end

  private

  def iamonline
    Presence.new.set_type :available
  end
end


class Grabber < JuickClient

  def connect
    super
    set_hook!
  end

  def thread(num)
    # ask for given thread plus comments
    say "##{num}+"
  end

  private

  def set_hook!    
    @connection.add_message_callback { |message| parse message.body + "\n" }
  end

  def parse(body)
    @body = body

    # checks
    return nil if body.lines.first =~ /Message not found/
    return nil unless body.lines.first =~ /\A@.+\:/

    puts 1

    # body
    lines = []

    body.lines.each_with_index do |line, ind|
      lines << {num: ind, text: line}
    end

    # who is the owner of this thread?
    link = lines.find { |line| line[:text] =~ /\A#\d+\s+http\:\/\/juick.com\/\d+\n\z/ }
    return nil unless link
    return nil unless lines[link[:num] + 1][:text] =~ /\A\n\z/

    puts 2

    thread = link[:text].match(/#(\d+)\s+/)[1]
    owner = lines[0][:text].match(/(@.+)\:/)[1]

    puts 3

    store_thread thread if owner == @nickname

    # is there any comments?
    return nil unless lines.find { |line| line[:text] =~ /\AReplies \(\d+\)\:\n\z/ }

    puts 4

    comments = []
    users = []

    lines[link[:num]..-1].each do |line|
      if line[:text] =~ /\A@.+\:\n\z/

        users << line[:text].match(/(@.+)\:/)[1]

      elsif line[:text] =~ /\A#\d+\/\d+\n\z/

        comments << line[:text].match(/#\d+\/(\d+)/)[1]

      end        
    end

    puts 5

    users.each_with_index do |user, ind|
      if user == @nickname
        store_comment thread, comments[ind]
      end
    end

    puts 6

  end

  def store_thread(num)
    puts "Thread :#{num}"
  end

  def store_comment(thread, num)
    puts "Comment :#{num}"
  end

end


juick = Grabber.new(
  'wyldrodney@headcounter.org',
  'Lf,k_"ynshghfqp',
  '@wyldrodney'
)

