# frozen_string_literal: true

# Copyright 2019 ConvertKit, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Stockpile
  # == Stockpile::YamlRedisConfiguration
  #
  # Confiuration object a multiple Redis database cache setup. Reads
  # configuration out of provided `.yml` file.
  module YamlRedisConfiguration
    module_function

    def configuration
      parsed_configuration.map do |database, settings|
        {
          db: database,
          pool_configuration: extract_pool(settings: settings),
          redis_configuration: extract_redis(settings: settings),
          compression: extract_compression(settings: settings)
        }
      end
    end

    def extract_compression(settings:)
      return true if settings['compression'].eql?(true)

      false
    end

    def extract_redis(settings:)
      sentinels = Stockpile::RedisConnectionsFactory.process_sentinels(
        sentinels: settings['sentinels'] || ''
      )

      {
        url: settings['url'],
        sentinels: sentinels
      }.delete_if { |_k, v| v.nil? || v.empty? }
    end

    def extract_pool(settings:)
      {
        size: settings.dig('pool_options', 'size'),
        timeout: settings.dig('pool_options', 'timeout')
      }
    end

    def parsed_configuration
      YAML.safe_load(
        ERB.new(
          raw_configuration
        ).result
      )
    end

    def raw_configuration
      File.open(Stockpile.configuration.configuration_file).read
    end
  end
end
