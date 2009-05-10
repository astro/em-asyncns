require 'eventmachine'
require File.dirname(__FILE__) + "/../ext/em_asyncns.so"

describe EventMachine::AsyncNS do
  it "should be allocatable" do
    a = EventMachine::AsyncNS.new
    a.should be_kind_of(EventMachine::AsyncNS)
  end

  it "should leak a file descriptor" do
    a = EventMachine::AsyncNS.new
    a.should respond_to(:fd)
    a.fd.should be_kind_of(Fixnum)
  end

  context "when resolving localhost" do
    it "should return a string identification for a query" do
      a = EventMachine::AsyncNS.new
      q = a.getaddrinfo("localhost.")
      q.should be_kind_of(String)
    end

    context "when waiting for a reply" do
      before(:all) do
        a = EventMachine::AsyncNS.new
        q = a.getaddrinfo("localhost.")
        res = {}
        while res.empty?
          a.read
          res.merge! a.getnext
        end
        @r = res[q]
      end
      
      it "should return 127.0.0.1" do
        @r.should include("127.0.0.1")
      end
      it "should return ::1" do
        @r.should include("::1")
      end
    end
  end

  context "when expecting an error" do
    before(:all) do
      a = EventMachine::AsyncNS.new
      q = a.getaddrinfo("invalid.")
      res = {}
      while res.empty?
        a.read
        res.merge! a.getnext
      end
      @r = res[q]
    end

    it "should return an error string" do
      @r.should be_kind_of(String)
    end
    it "should return NXDOMAIN" do
      @r.should == 'Name or service not known'
    end
  end
end

