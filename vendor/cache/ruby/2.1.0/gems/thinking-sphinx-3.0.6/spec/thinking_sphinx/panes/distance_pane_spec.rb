module ThinkingSphinx
  module Panes; end
end

require 'thinking_sphinx/panes/distance_pane'

describe ThinkingSphinx::Panes::DistancePane do
  let(:pane)    {
    ThinkingSphinx::Panes::DistancePane.new context, object, raw }
  let(:context) { double('context') }
  let(:object)  { double('object') }
  let(:raw)     { {} }

  describe '#distance' do
    it "returns the object's geodistance attribute by default" do
      raw['geodist'] = 123.45

      pane.distance.should == 123.45
    end

    it "converts string geodistances to floats" do
      raw['geodist'] = '123.450'

      pane.distance.should == 123.45
    end
  end

  describe '#geodist' do
    it "returns the object's geodistance attribute by default" do
      raw['geodist'] = 123.45

      pane.geodist.should == 123.45
    end

    it "converts string geodistances to floats" do
      raw['geodist'] = '123.450'

      pane.geodist.should == 123.45
    end
  end
end
