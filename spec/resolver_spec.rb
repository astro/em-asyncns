$: << File.dirname(__FILE__) + "/../ext/"
$: << File.dirname(__FILE__) + "/../lib/"
require 'em/resolver'

describe EventMachine::Resolver do
  it "should be initializable" do
    EM.run {
      r = EventMachine::Resolver.new
      r.should be_kind_of(EventMachine::Resolver)
      EM.stop
    }
  end

  context "when resolving localhost" do
    before(:all) do
      EM.run {
        r = EventMachine::Resolver.new
        q = r.getaddrinfo("localhost.")
        @callback = nil
        @errback = nil
        q.callback { |*a| @callback = a; EM.stop }
        q.errback { |*a| @errback = a; EM.stop }
      }
    end

    it "should pass one value to callback" do
      @callback.length.should == 1
    end
    it "should not call errback" do
      @errback.should be_nil
    end
    it "should resolve to 127.0.0.1" do
      @callback.first.should include("127.0.0.1")
    end
    it "should resolve to ::1" do
      @callback.first.should include("127.0.0.1")
    end
  end

  context "when expecting an error" do
    before(:all) do
      EM.run {
        r = EventMachine::Resolver.new
        q = r.getaddrinfo("invalid.")
        @callback = nil
        @errback = nil
        q.callback { |*a| @callback = a; EM.stop }
        q.errback { |*a| @errback = a; EM.stop }
      }
    end

    it "should return an error string" do
      @errback.first.should be_kind_of(String)
    end
    it "should return the correct error string" do
      @errback.first.should == 'Name or service not known'
    end
    it "should not resolve anything" do
      @callback.should be_nil
    end
  end

  ##
  # For this test it is suggested that you run a local DNS cache, such
  # as dnsmasq.
  context "when resolving localhost 1000 times parallely" do
    before(:all) do
      EM.run {
        r = EventMachine::Resolver.new
        1000.times do
          q = r.getaddrinfo("localhost.")
          @callbacks = []
          @errbacks = []
          q.callback { |r|
            @callbacks << r
            EM.stop if @callbacks.size + @errbacks.size >= 1000
          }
          q.errback { |e|
            @errbacks << e
            EM.stop if @callbacks.size + @errbacks.size >= 1000
          }
        end
      }
    end

    it "should perform 1000 callbacks" do
      @callbacks.size.should == 1000
    end
    it "should return no errors" do
      @errbacks.should be_empty
    end
  end
end
