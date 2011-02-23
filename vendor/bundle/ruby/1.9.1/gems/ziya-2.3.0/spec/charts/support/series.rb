require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

describe Ziya::Charts::Support::Series do
  before( :each ) do
    @comp = Ziya::Charts::Support::Series.new
  end
    
  it "should define the correct attribute methods" do
    lambda{ Ziya::Charts::Support::Series.attributes[@comp.class.name].each {
     |m| @comp.send( m ) } }.should_not raise_error
  end
    
  it "should flatten component correctly" do
    xml          = Builder::XmlMarkup.new
    @comp.switch = false
    @comp.flatten( xml ).should == "<series>false</series>"
  end
end
