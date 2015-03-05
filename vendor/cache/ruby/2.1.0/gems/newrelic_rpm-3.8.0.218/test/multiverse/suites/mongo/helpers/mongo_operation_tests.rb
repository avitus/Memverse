# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

module MongoOperationTests
  def test_records_metrics_for_insert
    @collection.insert(@tribble)

    metrics = build_test_metrics(:insert)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_find
    @collection.insert(@tribble)
    NewRelic::Agent.drop_buffered_data

    @collection.find(@tribble).to_a

    metrics = build_test_metrics(:find)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_find_one
    @collection.insert(@tribble)
    NewRelic::Agent.drop_buffered_data

    @collection.find_one

    metrics = build_test_metrics(:findOne)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_remove
    @collection.insert(@tribble)
    NewRelic::Agent.drop_buffered_data

    @collection.remove(@tribble).to_a

    metrics = build_test_metrics(:remove)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_save
    @collection.save(@tribble)

    metrics = build_test_metrics(:save)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_save_does_not_record_insert
    @collection.save(@tribble)

    metrics = build_test_metrics(:save)
    expected = metrics_with_attributes(metrics)

    assert_metrics_not_recorded(['Datastore/operation/MongoDB/insert'])
  end

  def test_records_metrics_for_update
    updated = @tribble.dup
    updated['name'] = 'codemonkey'

    @collection.update(@tribble, updated)

    metrics = build_test_metrics(:update)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_distinct
    @collection.distinct('name')

    metrics = build_test_metrics(:distinct)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_count
    @collection.count

    metrics = build_test_metrics(:count)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_group
    begin
      @collection.group({:key => "name",
                        :initial => {:count => 0},
                        :reduce => "function(k,v) { v.count += 1; }" })
    rescue Mongo::OperationFailure
      # We get occasional group failures, but should still record metrics
    end

    metrics = build_test_metrics(:group)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_find_and_modify
    updated = @tribble.dup
    updated['name'] = 'codemonkey'
    @collection.find_and_modify(:query => @tribble, :update => updated)

    metrics = build_test_metrics(:findAndModify)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_find_and_remove
    @collection.find_and_modify(:query => @tribble, :remove =>true)

    metrics = build_test_metrics(:findAndRemove)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_create_index
    @collection.create_index([[unique_field_name, Mongo::ASCENDING]])

    metrics = build_test_metrics(:createIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_ensure_index
    @collection.ensure_index([[unique_field_name, Mongo::ASCENDING]])

    metrics = build_test_metrics(:ensureIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_ensure_index_with_symbol
    @collection.ensure_index(unique_field_name.to_sym)

    metrics = build_test_metrics(:ensureIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_ensure_index_with_string
    @collection.ensure_index(unique_field_name)

    metrics = build_test_metrics(:ensureIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_ensure_index_does_not_record_insert
    @collection.ensure_index([[unique_field_name, Mongo::ASCENDING]])

    assert_metrics_not_recorded(['Datastore/operation/MongoDB/insert'])
  end

  def test_ensure_index_does_call_ensure_index
    options = [[unique_field_name, Mongo::ASCENDING]]

    @collection.expects(:ensure_index_without_new_relic_trace).with(options, any_parameters).once
    @collection.ensure_index(options)
  end

  def test_records_metrics_for_drop_index
    name =  @collection.create_index([[unique_field_name, Mongo::ASCENDING]])
    NewRelic::Agent.drop_buffered_data

    @collection.drop_index(name)

    metrics = build_test_metrics(:dropIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_drop_indexes
    @collection.create_index([[unique_field_name, Mongo::ASCENDING]])
    NewRelic::Agent.drop_buffered_data

    @collection.drop_indexes

    metrics = build_test_metrics(:dropIndexes)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_records_metrics_for_reindex
    @collection.create_index([[unique_field_name, Mongo::ASCENDING]])
    NewRelic::Agent.drop_buffered_data

    @database.command({ :reIndex => @collection_name })

    metrics = build_test_metrics(:reIndex)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_rename_collection
    ensure_collection_exists

    @collection.rename("renamed_#{@collection_name}")

    metrics = build_test_metrics(:renameCollection)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  ensure
    @collection_name = "renamed_#{@collection_name}"
  end

  def test_rename_collection_via_db
    ensure_collection_exists

    @database.rename_collection(@collection_name, "renamed_#{@collection_name}")

    metrics = build_test_metrics(:renameCollection)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  ensure
    @collection_name = "renamed_#{@collection_name}"
  end

  def test_drop_collection
    ensure_collection_exists

    @database.drop_collection(@collection_name)

    metrics = build_test_metrics(:drop)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_collstats
    @collection.insert(@tribble)
    NewRelic::Agent.drop_buffered_data
    @collection.stats

    metrics = build_test_metrics(:collstats)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_notices_nosql
    segment = nil

    in_transaction do
      @collection.insert(@tribble)
      segment = find_last_transaction_segment
    end

    expected = { :database   => @database_name,
                 :collection => @collection_name,
                 :operation  => :insert}

    result = segment.params[:statement]

    assert_equal expected, result, "Expected result (#{result}) to be #{expected}"
  end

  def test_noticed_nosql_includes_operation
    segment = nil

    in_transaction do
      @collection.insert(@tribble)
      segment = find_last_transaction_segment
    end

    expected = :insert

    query = segment.params[:statement]
    result = query[:operation]

    assert_equal expected, result
  end

  def test_noticed_nosql_includes_save_operation
    segment = nil

    in_transaction do
      @collection.save(@tribble)
      segment = find_last_transaction_segment
    end

    expected = :save

    query = segment.params[:statement]
    result = query[:operation]

    assert_equal expected, result
  end

  def test_noticed_nosql_includes_ensure_index_operation
    segment = nil

    in_transaction do
      @collection.ensure_index([[unique_field_name, Mongo::ASCENDING]])
      segment = find_last_transaction_segment
    end

    assert_ensure_index_in_transaction_segment(segment)
  end

  def test_noticed_nosql_includes_ensure_index_operation_with_symbol
    segment = nil

    in_transaction do
      @collection.ensure_index(unique_field_name.to_sym)
      segment = find_last_transaction_segment
    end

    assert_ensure_index_in_transaction_segment(segment)
  end

  def test_noticed_nosql_includes_ensure_index_operation_with_string
    segment = nil

    in_transaction do
      @collection.ensure_index(unique_field_name)
      segment = find_last_transaction_segment
    end

    assert_ensure_index_in_transaction_segment(segment)
  end

  def assert_ensure_index_in_transaction_segment(segment)
    query = segment.params[:statement]
    result = query[:operation]

    assert_equal :ensureIndex, result
  end

  def test_noticed_nosql_does_not_contain_documents
    segment = nil

    in_transaction do
      @collection.insert({'name' => 'soterios johnson'})
      segment = find_last_transaction_segment
    end

    statement = segment.params[:statement]

    refute statement.keys.include?(:documents), "Noticed NoSQL should not include documents: #{statement}"
  end

  def test_noticed_nosql_does_not_contain_selector_values
    @collection.insert({'password' => '$ecret'})
    segment = nil

    in_transaction do
      @collection.remove({'password' => '$ecret'})
      segment = find_last_transaction_segment
    end

    statement = segment.params[:statement]

    assert_equal '?', statement[:selector]['password']
  end

  def test_web_requests_record_all_web_metric
    NewRelic::Agent::Transaction.stubs(:recording_web_transaction?).returns(true)
    @collection.insert(@tribble)

    metrics = build_test_metrics(:insert)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_web_requests_do_not_record_all_other_metric
    NewRelic::Agent::Transaction.stubs(:recording_web_transaction?).returns(true)
    @collection.insert(@tribble)

    assert_metrics_not_recorded(['Datastore/allOther'])
  end

  def test_other_requests_record_all_other_metric
    NewRelic::Agent::Transaction.stubs(:recording_web_transaction?).returns(false)
    @collection.insert(@tribble)

    metrics = build_test_metrics(:insert, :other)
    expected = metrics_with_attributes(metrics)

    assert_metrics_recorded(expected)
  end

  def test_other_requests_do_not_record_all_web_metric
    NewRelic::Agent::Transaction.stubs(:recording_web_transaction?).returns(false)
    @collection.insert(@tribble)

    assert_metrics_not_recorded(['Datastore/allWeb'])
  end

  def test_insert_records_instance_metric
    @collection.insert(@tribble)
    assert_metrics_recorded(["Datastore/instance/MongoDB/localhost:#{@client.port}/#{@database_name}"])
  end

  def test_save_records_instance_metric
    @collection.save(@tribble)
    assert_metrics_recorded(["Datastore/instance/MongoDB/localhost:#{@client.port}/#{@database_name}"])
  end

  def test_ensure_index_records_instance_metric
    @collection.ensure_index([[unique_field_name, Mongo::ASCENDING]])
    assert_metrics_recorded(["Datastore/instance/MongoDB/localhost:#{@client.port}/#{@database_name}"])
  end

  def unique_field_name
    "field#{SecureRandom.hex(10)}"
  end

  def ensure_collection_exists
    @collection.insert(:junk => "data")
    NewRelic::Agent.drop_buffered_data
  end

end
