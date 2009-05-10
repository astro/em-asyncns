require 'em/resolver'

module Dnsruby
  class Resolver
    def self.use_eventmachine
      # Of course I will!
    end

    def self.start_eventmachine_loop(really)
      if really
        raise 'My own EventMachine loop is not implemented'
      else
        # Of course I won't!
      end
    end

    def initialize
      @res = EventMachine::Resolver.new
    end

    def send_async(msg)
      proxy_df = EventMachine::DefaultDeferrable.new
      df = @res.getaddrinfo(msg)

      df.callback { |addresses|
        class << addresses
          # Ask no further, I *am* the answer!
          def answer
            self
          end
        end
        proxy_df.succeed addresses
      }
      df.errback { |error|
        proxy_df.fail error, 666
      }

      proxy_df
    end
  end

  class Message < String
  end
end
