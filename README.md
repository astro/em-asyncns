Motivation
==========

Connecting to hostnames from EventMachine?  Dissatisfied from the
Dnsruby experience?  Disappointed by the lack of EventMachine support
in Dnsruby trunk?  Then you want this.


Usage
=====

        require 'em/resolver'
        
        EM.run {
          res = EventMachine::Resolver.new
          q = res.getaddrinfo("localhost")
          q.callback do |addresses|
            addresses.each { |address|
              spam! address
            }
          end
          q.errback do |error|
            puts "Oh noes: #{error}"
          end
        }


Dnsruby compatibility
=====================

A drop-in replacement for Dnsruby is provided given you use the
library exactly as stated in the [EventMachine FAQ](http://rubyeventmachine.com/wiki/FAQ#DoesEMblockonDNSresolutionsi.e.ifyoustartaconnectiontotakes_ages.comwillittemporarilyblocktheotherprocesseswhileitworks).

See spec/dnsruby_spec.rb for details.


ext/asyncns.h
=========

...is included in a slightly modified form because the original one
had parameter names like `class' which prevents compiling as C++.

