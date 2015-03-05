# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

class Marshalling < Performance::TestCase
  def setup
    @payload = build_analytics_events_payload
    @tt_payload = build_transaction_trace_payload
  end

  skip_test :test_basic_marshalling_json, :platforms => :mri_18

  def test_basic_marshalling_json(timer)
    marshaller = NewRelic::Agent::NewRelicService::JsonMarshaller.new
    timer.measure do
      (iterations / 100).times do
        marshaller.dump(@payload)
        marshaller.dump(@tt_payload)
      end
    end
  end

  def test_json_marshalling_binary_strings(timer)
    marshaller = NewRelic::Agent::NewRelicService::JsonMarshaller.new
    convert_strings_to_binary(@payload)
    convert_strings_to_binary(@tt_payload)
    timer.measure do
      (iterations / 100).times do
        marshaller.dump(@payload)
        marshaller.dump(@tt_payload)
      end
    end
  end

  def test_json_marshalling_utf16_strings(timer)
    marshaller = NewRelic::Agent::NewRelicService::JsonMarshaller.new
    convert_strings_to_utf16(@payload)
    convert_strings_to_utf16(@tt_payload)
    timer.measure do
      (iterations / 100).times do
        marshaller.dump(@payload)
        marshaller.dump(@tt_payload)
      end
    end
  end

  def test_json_marshalling_latin1_strings(timer)
    marshaller = NewRelic::Agent::NewRelicService::JsonMarshaller.new
    convert_strings_to_latin1(@payload)
    convert_strings_to_latin1(@tt_payload)
    timer.measure do
      (iterations / 100).times do
        marshaller.dump(@payload)
        marshaller.dump(@tt_payload)
      end
    end
  end

  def test_basic_marshalling_pruby(timer)
    marshaller = NewRelic::Agent::NewRelicService::PrubyMarshaller.new
    timer.measure do
      (iterations / 100).times do
        marshaller.dump(@payload)
        marshaller.dump(@tt_payload)
      end
    end
  end

  # Skips Strings used as Hash keys, since they are frozen
  def each_string(object, &blk)
    case object
    when String
      blk.call(object)
    when Array
      object.map! { |x| each_string(x, &blk) }
    when Hash
      object.values.each do |v|
        each_string(v, &blk)
      end
    end
  end

  BYTE_ALPHABET = (0..255).to_a.freeze

  def generate_random_string(length)
    bytes = []
    length.times { bytes << BYTE_ALPHABET.sample }
    bytes.pack("C*")
  end

  def convert_strings_to_binary(object)
    each_string(object) do |s|
      s.replace(generate_random_string(s.bytesize))
    end
  end

  def convert_strings_to_utf16(object)
    each_string(object) do |s|
      s.encode!('UTF-16')
    end
  end

  def convert_strings_to_latin1(object)
    each_string(object) do |s|
      s.replace(generate_random_string(s.bytesize)).force_encoding('ISO-8859-1')
    end
  end

  # Build an object graph that approximates a transaction trace in structure
  def build_transaction_trace_payload(depth=6)
    root = []
    fanout = depth
    fanout.times do |i|
      node = [
        i * rand(10),
        i * rand(10),
        "This/Is/The/Name/Of/A/Transaction/Trace/Node/Depth/#{depth}/#{i}",
        {
          "sql" => "SELECT #{(0..100).to_a.join(",")}"
        },
        []
      ]
      node[-1] = build_transaction_trace_payload(depth-1) if depth > 0
      root << node
    end
    root
  end

  # Build an object graph that approximates a large analytics_event_data payload
  def build_analytics_events_payload
    events = []
    1000.times do
      event = {
        :timestamp        => Time.now.to_f,
        :name             => "Controller/foo/bar",
        :type             => "Transaction",
        :duration         => rand,
        :databaseDuration => rand,
        :databaseCallCount=> rand,
        :gcCumulative     => rand,
        :host             => 'lo-calhost',
        :color            => 'blue-green',
        :shape            => 'squarish',
        :texture          => 'sort of lumpy like a bag of frozen peas'
      }
      events << [event]
    end
    [rand(1000000), events]
  end
end
