$: << File.dirname(__FILE__) + "/../ext/"
$: << File.dirname(__FILE__) + "/../lib/"
require 'em/resolver'
# By commenting this line you can make sure this code is right with
# the original Dnsruby.
require 'Dnsruby'

##
# Example usage:
#   http://rubyeventmachine.com/wiki/FAQ#DoesEMblockonDNSresolutionsi.e.ifyoustartaconnectiontotakes_ages.comwillittemporarilyblocktheotherprocesseswhileitworks
describe Dnsruby::Resolver do
  it "should use EventMachine" do
    Dnsruby::Resolver.use_eventmachine
  end

  it "should not start EventMachine loop" do
    Dnsruby::Resolver.start_eventmachine_loop(false)
  end

  context "when resolving localhost" do
    before(:all) do
      EM.run {
        res = Dnsruby::Resolver.new
        df = res.send_async(Dnsruby::Message.new("localhost."))
        df.callback { |*a| @callback = a; EM.stop }
        df.errback { |*a| @errback = a; EM.stop }
      }
    end

    it "should callback" do
      @callback.length.should == 1
    end
    it "should not errback" do
      @errback.should be_nil
    end
    it "should have an answer" do
      @callback.first.should respond_to(:answer)
    end
    it "should resolve localhost to 127.0.0.1" do
      @callback.first.answer.should contain_address("127.0.0.1")
    end
    it "should resolve localhost to ::1" do
      @callback.first.answer.should contain_address("::1")
    end
  end

  context "when resolving invalid" do
    before(:all) do
      EM.run {
        res = Dnsruby::Resolver.new
        df = res.send_async(Dnsruby::Message.new("invalid."))
        df.callback { |*a| @callback = a; EM.stop }
        df.errback { |*a| @errback = a; EM.stop }
      }
    end

    it "should not callback" do
      @callback.should be_nil
    end
    it "should errback" do
      @errback.length.should == 2
    end

  end
end

Spec::Matchers.define :contain_address do |address|
  match do |addresses|
    addresses.each do |a|
      addresses == a.to_s
    end
  end
end
