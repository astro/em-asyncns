require 'eventmachine'
require 'em_asyncns'

module EventMachine
  module Resolver

    def self.new
      asyncns = AsyncNS.new
      EM.attach asyncns.fd, self, asyncns
    end

    def initialize(asyncns)
      @asyncns = asyncns
      @queries = {}
    end

    def notify_readable
      @asyncns.read
      @asyncns.getnext.each do |query_id,result|
        deferrable = @queries[query_id] or raise 'Unknown result from AsyncNS'
        case result
        when Array
          deferrable.succeed result
        when String
          deferrable.fail result
        else
          raise 'Bogus result from AsyncNS'
        end
        @queries.delete(query_id)
      end
    end

    def getaddrinfo(name)
      query_id = @asyncns.getaddrinfo(name)
      deferrable = DefaultDeferrable.new

      if Resolver.is_null?(query_id)
        # Probably libasyncns MAX_QUERIES exceeded

        # next_tick, because the user still has to attach an errback
        EM.next_tick { deferrable.fail 'Cannot query' }
      else
        @queries[query_id] = deferrable
      end

      deferrable
    end

    def self.is_null?(str)
      str =~ /^\000+$/
    end

  end
end
