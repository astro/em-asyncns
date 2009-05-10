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
      @queries[query_id] = deferrable
      deferrable
    end

  end
end
