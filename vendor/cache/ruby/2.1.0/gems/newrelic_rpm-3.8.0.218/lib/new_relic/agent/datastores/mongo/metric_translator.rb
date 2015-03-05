# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require 'new_relic/agent/datastores/mongo/obfuscator'

module NewRelic
  module Agent
    module Datastores
      module Mongo
        module MetricTranslator
          def self.metrics_for(name, payload, request_type = :web)
            payload ||= {}

            database = payload[:database]
            collection = payload[:collection]

            if collection_in_selector?(collection, payload)
              command_key = command_key_from_selector(payload)
              name        = get_name_from_selector(command_key, payload)
              collection  = get_collection_from_selector(command_key, payload)
            end

            if self.find_one?(name, payload)
              name = 'findOne'
            elsif self.find_and_remove?(name, payload)
              name = 'findAndRemove'
            elsif self.find_and_modify?(name, payload)
              name = 'findAndModify'
            elsif self.create_index?(name, payload)
              name = 'createIndex'
              collection = self.collection_name_from_index(payload)
            elsif self.drop_indexes?(name, payload)
              name = 'dropIndexes'
            elsif self.drop_index?(name, payload)
              name = 'dropIndex'
            elsif self.re_index?(name, payload)
              name = 'reIndex'
            elsif self.group?(name, payload)
              name = 'group'
              collection = collection_name_from_group_selector(payload)
            elsif self.rename_collection?(name, payload)
              name = 'renameCollection'
              collection = collection_name_from_rename_selector(payload)
            end

            metrics = build_metrics(name, collection, request_type)

            metrics
          end

          def self.build_metrics(name, collection, request_type = :web)
            default_metrics = [
              "Datastore/statement/MongoDB/#{collection}/#{name}",
              "Datastore/operation/MongoDB/#{name}",
              "Datastore/all"
            ]

            if request_type == :web
              default_metrics << 'ActiveRecord/all'
              default_metrics << 'Datastore/allWeb'
            else
              default_metrics << 'Datastore/allOther'
            end

            default_metrics
          end

          def self.instance_metric(host, port, database)
            "Datastore/instance/MongoDB/#{host}:#{port}/#{database}"
          end

          def self.collection_in_selector?(collection, payload)
            collection == '$cmd' && payload[:selector]
          end

          NAMES_IN_SELECTOR = [
            :findandmodify,

            "aggregate",
            "count",
            "group",
            "mapreduce",

            :distinct,

            :deleteIndexes,
            :reIndex,

            :collstats,
            :renameCollection,
            :drop,
          ]

          def self.command_key_from_selector(payload)
            selector = payload[:selector]
            NAMES_IN_SELECTOR.find do |check_name|
              selector.key?(check_name)
            end
          end

          def self.get_name_from_selector(command_key, payload)
            if command_key
              command_key.to_sym
            else
              NewRelic::Agent.increment_metric("Supportability/Mongo/UnknownCollection")
              payload[:selector].first.first unless command_key
            end
          end

          CMD_COLLECTION = "$cmd".freeze

          def self.get_collection_from_selector(command_key, payload)
            if command_key
              payload[:selector][command_key]
            else
              NewRelic::Agent.increment_metric("Supportability/Mongo/UnknownCollection")
              CMD_COLLECTION
            end
          end

          def self.find_one?(name, payload)
            name == :find && payload[:limit] == -1
          end

          def self.find_and_modify?(name, payload)
            name == :findandmodify
          end

          def self.find_and_remove?(name, payload)
            name == :findandmodify && payload[:selector] && payload[:selector][:remove]
          end

          def self.create_index?(name, payload)
            name == :insert && payload[:collection] == "system.indexes"
          end

          def self.drop_indexes?(name, payload)
            name == :deleteIndexes && payload[:selector] && payload[:selector][:index] == "*"
          end

          def self.drop_index?(name, payload)
            name == :deleteIndexes
          end

          def self.re_index?(name, payload)
            name == :reIndex && payload[:selector] && payload[:selector][:reIndex]
          end

          def self.group?(name, payload)
            name == :group
          end

          def self.rename_collection?(name, payload)
            name == :renameCollection
          end

          def self.collection_name_from_index(payload)
            if payload[:documents] && payload[:documents].first[:ns]
              payload[:documents].first[:ns].split('.').last
            else
              'system.indexes'
            end
          end

          def self.collection_name_from_group_selector(payload)
            payload[:selector]["group"]["ns"]
          end

          def self.collection_name_from_rename_selector(payload)
            parts = payload[:selector][:renameCollection].split('.')
            parts.shift
            parts.join('.')
          end

        end

      end
    end
  end
end
