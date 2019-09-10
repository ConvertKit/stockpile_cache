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
  # == Stockpile::Configuration
  #
  # Holds configuration for cache with writeable attributes allowing
  # dynamic change of configuration during runtime
  class Configuration
    attr_accessor :connection_pool, :connection_timeout, :lock_expiration,
                  :redis_url, :sentinels, :slumber

    def initialize
      @connection_pool = extract_connection_pool
      @connection_timeout = extract_connection_timeout
      @lock_expiration = extract_lock_expiration
      @redis_url = extract_redis_url
      @sentinels = process_sentinels
      @slumber = extract_slumber
    end

    private

    def extract_connection_pool
      ENV.fetch(
        'STOCKPILE_CONNECTION_POOL',
        Stockpile::DEFAULT_CONNECTION_POOL
      ).to_i
    end

    def extract_connection_timeout
      ENV.fetch(
        'STOCKPILE_CONNECTION_TIMEOUT',
        Stockpile::DEFAULT_CONNECTION_TIMEOUT
      ).to_i
    end

    def extract_lock_expiration
      ENV.fetch(
        'STOCKPILE_LOCK_EXPIRATION',
        Stockpile::DEFAULT_LOCK_EXPIRATION
      ).to_i
    end

    def extract_redis_url
      ENV.fetch(
        'STOCKPILE_REDIS_URL',
        Stockpile::DEFAULT_REDIS_URL
      )
    end

    def extract_slumber
      ENV.fetch(
        'STOCKPILE_SLUMBER',
        Stockpile::DEFAULT_SLUMBER
      ).to_i
    end

    def process_sentinels
      ENV.fetch('STOCKPILE_REDIS_SENTINELS', '').split(',').map do |sentinel|
        host, port = sentinel.split(':')
        { host: host, port: port.to_i }
      end
    end
  end
end
