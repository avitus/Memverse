require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Association do
  let(:association) { ThinkingSphinx::ActiveRecord::Association.new column }
  let(:column)      { double('column', :__stack => [:users], :__name => :post) }

  describe '#stack' do
    it "returns the column's stack and name" do
      association.stack.should == [:users, :post]
    end
  end
end
