# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
require 'new_relic/rack/browser_monitoring'
require 'new_relic/rack/developer_mode'
class NewRelic::Rack::AllTest < Minitest::Test
  # just here to load the files above

  def test_truth
    assert true
  end
end
