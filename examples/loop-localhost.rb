#!/usr/bin/env ruby
#
# Find space leaks
#

$: << File.dirname(__FILE__) + "/../lib"
$: << File.dirname(__FILE__) + "/../ext"

require 'em/resolver'

EM.run {
  $res = EM::Resolver.new
  $pending = 0
  def ensure_pending
    while $pending < 10
      q = $res.getaddrinfo("localhost.")
      q.callback {
        $pending -= 1
        ensure_pending
      }
      q.errback { |e|
        raise e
      }
      $pending += 1
    end
  end
  ensure_pending
}
