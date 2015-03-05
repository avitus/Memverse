# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

DependencyDetection.defer do
  named :mongo

  depends_on do
    if defined?(::Mongo) && defined?(::Mongo::Logging)
      true
    else
      if defined?(::Mongo)
        NewRelic::Agent.logger.info 'Mongo instrumentation requires Mongo::Logging'
      end

      false
    end
  end

  depends_on do
    require 'new_relic/agent/datastores/mongo'
    NewRelic::Agent::Datastores::Mongo.is_supported_version?
  end

  executes do
    NewRelic::Agent.logger.info 'Installing Mongo instrumentation'
    install_mongo_instrumentation
  end

  def install_mongo_instrumentation
    setup_logging_for_instrumentation
    instrument_mongo_logging
    instrument_save
    instrument_ensure_index
  end

  def setup_logging_for_instrumentation
    ::Mongo::Logging.class_eval do
      include NewRelic::Agent::MethodTracer
      require 'new_relic/agent/datastores/mongo/metric_generator'
      require 'new_relic/agent/datastores/mongo/statement_formatter'

      def new_relic_instance_metric_builder
        Proc.new do
          if @pool
            host, port = @pool.host, @pool.port
          elsif @connection && (primary = @connection.primary)
            host, port = primary[0], primary[1]
          end

          database_name = @db.name if @db
          NewRelic::Agent::Datastores::Mongo::MetricGenerator.generate_instance_metric_for(host, port, database_name)
        end
      end

      # It's key that this method eats all exceptions, as it rests between the
      # Mongo operation the user called and us returning them the data. Be safe!
      def new_relic_notice_statement(t0, payload, operation)
        payload[:operation] = operation
        statement = NewRelic::Agent::Datastores::Mongo::StatementFormatter.format(payload)
        if statement
          NewRelic::Agent.instance.transaction_sampler.notice_nosql_statement(statement, (Time.now - t0).to_f)
        end
      rescue => e
        NewRelic::Agent.logger.debug("Exception during Mongo statement gathering", e)
      end

      def new_relic_generate_metrics(operation, payload = nil)
        payload ||= { :collection => self.name, :database => self.db.name }
        metrics = NewRelic::Agent::Datastores::Mongo::MetricGenerator.generate_metrics_for(operation, payload)
      end

      ::Mongo::Collection.class_eval { include Mongo::Logging; }
      ::Mongo::Connection.class_eval { include Mongo::Logging; }
      ::Mongo::Cursor.class_eval { include Mongo::Logging; }
    end
  end

  def instrument_mongo_logging
    ::Mongo::Logging.class_eval do
      def instrument_with_new_relic_trace(name, payload = {}, &block)
        metrics = new_relic_generate_metrics(name, payload)

        trace_execution_scoped(metrics, :additional_metrics_callback => new_relic_instance_metric_builder) do
          t0 = Time.now
          result = instrument_without_new_relic_trace(name, payload, &block)
          new_relic_notice_statement(t0, payload, name)
          result
        end
      end

      alias_method :instrument_without_new_relic_trace, :instrument
      alias_method :instrument, :instrument_with_new_relic_trace
    end
  end

  def instrument_save
    ::Mongo::Collection.class_eval do
      def save_with_new_relic_trace(doc, opts = {}, &block)
        metrics = new_relic_generate_metrics(:save)
        trace_execution_scoped(metrics, :additional_metrics_callback => new_relic_instance_metric_builder) do
          t0 = Time.now

          transaction_state = NewRelic::Agent::TransactionState.get
          transaction_state.push_traced(false)

          begin
            result = save_without_new_relic_trace(doc, opts, &block)
          ensure
            transaction_state.pop_traced
          end

          new_relic_notice_statement(t0, doc, :save)
          result
        end
      end

      alias_method :save_without_new_relic_trace, :save
      alias_method :save, :save_with_new_relic_trace
    end
  end

  def instrument_ensure_index
    ::Mongo::Collection.class_eval do
      def ensure_index_with_new_relic_trace(spec, opts = {}, &block)
        metrics = new_relic_generate_metrics(:ensureIndex)
        trace_execution_scoped(metrics, :additional_metrics_callback => new_relic_instance_metric_builder) do
          t0 = Time.now

          transaction_state = NewRelic::Agent::TransactionState.get
          transaction_state.push_traced(false)

          begin
            result = ensure_index_without_new_relic_trace(spec, opts, &block)
          ensure
            transaction_state.pop_traced
          end

          spec = case spec
                 when Array
                   Hash[spec]
                 when String, Symbol
                   { spec => 1 }
                 else
                   spec.dup
                 end

          new_relic_notice_statement(t0, spec, :ensureIndex)
          result
        end
      end

      alias_method :ensure_index_without_new_relic_trace, :ensure_index
      alias_method :ensure_index, :ensure_index_with_new_relic_trace
    end
  end
end
