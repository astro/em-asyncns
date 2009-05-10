require 'eventmachine'
require 'em_asyncns'

module EventMachine
  module Resolver

    def self.new
      asyncns = AsyncNS.new
      EM.attach asyncns.fd, self, asyncns
    end

    ##
    # EM callback, supplied with AsyncNS instance by Resolver.new
    def initialize(asyncns)
      @asyncns = asyncns

      # Haven't sent yet
      # [[name, deferrable]]
      @pending_queries = []

      # Expecting reply
      # { query_id => [deferrable] }
      @queries = {}
    end

    def post_init
      # Is libasyncns having timeout handling at all?
      EM::PeriodicTimer.new(0.5) do
        notify_readable
      end
    end

    ##
    # EM callback
    def notify_readable
      @asyncns.read
      @asyncns.getnext.each do |query_id,result|
        if (deferrables = @queries[query_id])
          case result
          when Array
            deferrables.each { |deferrable|
              deferrable.succeed result
            }
          when String
            deferrables.each { |deferrable|
              deferrable.fail result
            }
          else
            raise 'Bogus result from AsyncNS'
          end
          @queries.delete(query_id)
        end
      end
      send_pending_queries
    end

    ##
    # Returns Symbols in various situations. In that case, query
    # should be made pending again by send_pending_queries because we
    # have reached libasyncns' MAX_QUERIES. If this error is
    # reproducably fatal, we're going to loop here.
    #
    # TODO: look for real-world behaviour.
    def getaddrinfo_do(name)
      query_id = @asyncns.getaddrinfo(name)

      if Resolver.is_null?(query_id)
        :is_null
      elsif @queries.has_key?(query_id)
        :dup_id
      else
        query_id
      end
    end

    def send_pending_queries
      new_pending_queries = []
      @pending_queries.each do |name,deferrable|
        query_id = getaddrinfo_do(name)
        case query_id
        when :is_null
          new_pending_queries << [name, deferrable]
        when :is_dup
          @query[query_id] << deferrable
        when String
          #p :sent
          @queries[query_id] = [deferrable]
        end
      end
      @pending_queries = new_pending_queries
    end

    def getaddrinfo(name)
      deferrable = DefaultDeferrable.new
      @pending_queries << [name, deferrable]
      send_pending_queries
      deferrable
    end

    def self.is_null?(str)
      str =~ /^\000+$/
    end

  end
end
