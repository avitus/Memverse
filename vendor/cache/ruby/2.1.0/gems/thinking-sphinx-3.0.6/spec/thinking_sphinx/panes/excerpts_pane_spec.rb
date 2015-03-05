module ThinkingSphinx
  module Panes; end
end

require 'thinking_sphinx/panes/excerpts_pane'

describe ThinkingSphinx::Panes::ExcerptsPane do
  let(:pane)    {
    ThinkingSphinx::Panes::ExcerptsPane.new context, object, raw }
  let(:context) { {:indices => [double(:name => 'foo_core')]} }
  let(:object)  { double('object') }
  let(:raw)     { {} }
  let(:search)  { double('search', :query => 'foo', :options => {}) }

  before :each do
    context.stub :search => search
  end

  describe '#excerpts' do
    let(:excerpter) { double('excerpter') }
    let(:excerpts)  { double('excerpts object') }

    before :each do
      stub_const 'ThinkingSphinx::Excerpter', double(:new => excerpter)
      ThinkingSphinx::Panes::ExcerptsPane::Excerpts.stub :new => excerpts
    end

    it "returns an excerpt glazing" do
      pane.excerpts.should == excerpts
    end

    it "creates an excerpter with the first index and the query and conditions values" do
      context[:indices] = [double(:name => 'alpha'), double(:name => 'beta')]
      context.search.options[:conditions] = {:baz => 'bar'}

      ThinkingSphinx::Excerpter.should_receive(:new).
        with('alpha', 'foo bar', anything).and_return(excerpter)

      pane.excerpts
    end

    it "passes through excerpts options" do
      search.options[:excerpts] = {:before_match => 'foo'}

      ThinkingSphinx::Excerpter.should_receive(:new).
        with(anything, anything, :before_match => 'foo').and_return(excerpter)

      pane.excerpts
    end
  end
end
