require 'spec_helper'
require 'split/metric'

describe Split::Metric do
  describe 'possible experiments' do
    it "should load the experiment if there is one, but no metric" do
      experiment = Split::Experiment.find_or_create('color', 'red', 'blue')
      Split::Metric.possible_experiments('color').should == [experiment]
    end

    it "should load the experiments in a metric" do
      experiment1 = Split::Experiment.find_or_create('color', 'red', 'blue')
      experiment2 = Split::Experiment.find_or_create('size', 'big', 'small')

      metric = Split::Metric.new(:name => 'purchase', :experiments => [experiment1, experiment2])
      metric.save
      Split::Metric.possible_experiments('purchase').should include(experiment1, experiment2)
    end

    it "should load both the metric experiments and an experiment with the same name" do
      experiment1 = Split::Experiment.find_or_create('purchase', 'red', 'blue')
      experiment2 = Split::Experiment.find_or_create('size', 'big', 'small')

      metric = Split::Metric.new(:name => 'purchase', :experiments => [experiment2])
      metric.save
      Split::Metric.possible_experiments('purchase').should include(experiment1, experiment2)
    end
  end

end
