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

    puts "OK"
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
    @connection.add_message_callback { |message| parse message.body }
  end

  def parse(body)
    puts body

    # checks
    return nil if body.lines.first =~ /Message not found/
    return nil if body.lines.first =~ /\A@.+\:\n\z/

    # body
    lines = []

    body.lines.each_with_index do |line, ind|
      lines << {num: ind, text: line}
    end

    # who is the owner of this thread?
    link = lines.find { |line| line[:text] =~ /\A#\d+\s+http\:\/\/juick.com\/\d+\n\z/ }
    return nil unless link
    return nil unless lines[link[:num] + 1][:text] =~ /\A\n\z/

    user = lines[0...link[:num]].find { |line| line[:text] =~ /\A@.+\:\n\z/ }
    return nil unless link user

    thread = link[:text].match(/#(\d+)\s+/)[1]
    username = user[:text].match(/(@.+)\:\n/)[1]

    store_thread thread if username == @username

    # is there any comments?
    comments = lines.find { |line| line[:line] =~ /\AReplies \(\d+\)\:\n/ }

  end

  def store_thread(num)

  end

end


juick = Grabber.new(
  'wyldrodney@headcounter.org',
  'Lf,k_"ynshghfqp',
  '@wyldrodney'
)

