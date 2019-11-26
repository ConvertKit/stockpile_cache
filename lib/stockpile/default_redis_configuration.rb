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
  # == Stockpile::DefaultRedisConfiguration
  #
  # Confiuration object for a single Redis database cache setup.
  # Reads values out of environment, default values or uses
  # configuration provided during runtime.
  module DefaultRedisConfiguration
    module_function

    def configuration
      [
        {
          db: :default,
          pool_configuration: pool_configuration,
          redis_configuration: redis_configuration
        }
      ]
    end

    def redis_configuration
      {
        url: redis_url,
        sentinels: sentinels
      }.delete_if { |_k, v| v.nil? || v.empty? }
    end

    def pool_configuration
      {
        size: pool_size,
        timeout: connection_timeout
      }
    end

    def connection_timeout
      Stockpile.configuration.connection_timeout
    end

    def pool_size
      Stockpile.configuration.connection_pool
    end

    def redis_url
      Stockpile.configuration.redis_url
    end

    def sentinels
      Stockpile.configuration.sentinels
    end
  end
end
