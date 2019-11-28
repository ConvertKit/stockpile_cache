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
  # == Stockpile::RedisConnectionsFactory
  #
  # Builds out connection pools out of provided configuration. Configurations
  # are built with `*RedisConfiguration` classes. Providing a `.yml` file will
  # override everything else and use that to build a config.
  module RedisConnectionsFactory
    module_function

    def build_connections
      configuration.each do |database|
        pool = ConnectionPool.new(database[:pool_configuration]) do
          Redis.new(database[:redis_configuration])
        end

        RedisConnections.instance_variable_set(
          "@#{database[:db]}".to_sym,
          pool
        )
      end

      RedisConnections
    end

    def configuration
      if Stockpile.configuration.configuration_file
        Stockpile::YamlRedisConfiguration.configuration
      else
        Stockpile::DefaultRedisConfiguration.configuration
      end
    end

    def process_sentinels(sentinels:)
      sentinels.split(',').map do |sentinel|
        host, port = sentinel.split(':')
        { host: host, port: port.to_i }
      end
    end
  end
end
