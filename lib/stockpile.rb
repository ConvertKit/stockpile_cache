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

require 'connection_pool'
require 'oj'
require 'redis'
require 'timeout'

require 'stockpile/constants'
require 'stockpile/configuration'
require 'stockpile/redis_connection'

require 'stockpile/lock'
require 'stockpile/locked_execution_result'
require 'stockpile/failed_lock_execution'

require 'stockpile/cache'
require 'stockpile/cached_value_reader'
require 'stockpile/cached_value_expirer'

require 'stockpile/executor'

# = Stockpile
#
# Simple cache with Redis as a backend and a built in cache-stampede
# protection. For more information on general usage consider consulting
# README.md file.
#
# While interacting with the cache from within your application
# avoid re-using anything after :: notation as it is part of internal API
# and is subject to an un-announced breaking change.
#
# Stockpile provides 5 methods as part of it's public API:
# * configuration
# * configure
# * perform_cached
# * redis
# * redis_connection_pool
module Stockpile
  module_function

  # Provides access to cache's configuration.
  #
  # @return [Configuration] the object holding configuration values
  def configuration
    @configuration ||= Configuration.new
  end

  # API to configure cache dynamically during runtime.
  #
  # @yield [configuration] Takes in a block of code of code that is setting
  #   or changing configuration values
  #
  # @example Configure during runtime changing redis URL
  #   Stockpile.configure { |c| c.redis_url = 'foobar' }
  #
  # @return [void]
  def configure
    yield(configuration)
    nil
  end

  # Immediatelly expires a cached value for a given key.
  #
  # @params key [String] Key to expire
  #
  # @return [true, false] Returns true if value existed in cache and was
  #   succesfully expired. Returns false if value did not exist in cache.
  def expire_cached(key:)
    Stockpile::CachedValueExpirer.expire_cached(key: key)
  end

  # Attempts to fetch a value from cache (for a given key). In case of miss
  # will execute given block of code and cache it's result at the provided
  # key for a specified TTL.
  #
  # @param key [String] Key to use for a value lookup from cache or key
  #   to store value at once it is computed
  # @param ttl [Integer] (optional) Time in seconds to expire cache after.
  #   Defaults to Stockpile::DEFAULT_TTL
  #
  # @yield [block] A block of code to be executed in case of cache miss
  #
  # @example Perform cache operation
  #   Stockpile.perform_cached(key: 'meaning_of_life', ttl: 42) { 21 * 2 }
  #
  # @return Returns a result of block execution
  def perform_cached(key:, ttl: Stockpile::DEFAULT_TTL, &block)
    Stockpile::CachedValueReader.read_or_yield(key: key, ttl: ttl, &block)
  end

  # API to communicate with Redis database backing cache up.
  #
  # @yield [redis]
  #
  # @example Store a value in Redis at given key
  #   Store.redis { |r| r.set('meaning_of_life', 42) }
  #
  # @return Returns a result of interaction with Redis
  def redis
    redis_connection_pool.with do |connection|
      yield connection
    end
  end

  # Accessor to connection pool. Defined on top level so it can be memoized
  # on the topmost level
  #
  # @return [ConnectionPool] ConnectionPool object from connection_pool gem
  def redis_connection_pool
    @redis_connection_pool ||= Stockpile::RedisConnection.connection_pool
  end
end
