module Cinch
  module Plugins
    module Memo
      class Base
        include Cinch::Plugin
        attr_accessor :backend

        class << self
          attr_accessor :store, :host, :port, :db, :collection

          def configure(&block)
            yield self
          end
        end

        def initialize(*args)
          super
          @backend =
          case self.class.store
          when :redis then Cinch::Plugins::Memo::Redis.new(self.class.host, self.class.port)
          when :mongo then Cinch::Plugins::Memo::Mongo.new(self.class.host, self.class.port, :db => self.class.db, :collection => self.class.collection)
          else
            self.class.store
          end
        end

        match %r{memo (.+?) (.+)}, :method => :store_message
        match "memo?",             :method => :get_message

        listen_to :join

        def listen(m)
          messages = @backend.retrieve(m.user.nick)
          if messages || !messages.empty?
            messages.each { |msg| m.user.send(msg) }
          end
        end

        # Stores message to designated user.
        def store_message(m, nick, message)
          if nick == @bot.nick
            m.reply "You can't store a message for me."
          else
            @backend.store(nick,m.user.nick, message)
            m.reply "Message saved!"
          end
        end

        # Gets messages for the designated user
        def get_message(m)
          messages = @backend.retrieve(m.user.nick)
          unless messages.nil? || messages.empty?
            messages.each { |msg| m.reply msg }
          else
            m.reply "There are no messages for you."
          end
        end

      end # Base

    end # Memo
  end # Plugins
end #Cinch
