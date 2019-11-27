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
require 'yaml'

require 'stockpile/constants'
require 'stockpile/configuration'
require 'stockpile/redis_connections_factory'
require 'stockpile/default_redis_configuration'
require 'stockpile/yaml_redis_configuration'
require 'stockpile/redis_connections'

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
# protection and multiple Redid database support. For more information on
# general usage consider consulting README.md file.
#
# While interacting with the cache from within your application
# avoid re-using anything after :: notation as it is part of internal API
# and is subject to an un-announced breaking change.
#
# Stockpile provides 6 methods as part of it's public API:
# * configuration
# * configure
# * expire_cached
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

  # API to configure cache dynamically during runtime. Running dynamic
  # configuration will rebuild connection pools releasing existing
  # connections.
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
    @redis_connections = Stockpile::RedisConnectionsFactory.build_connections

    nil
  end

  # Immediatelly expires a cached value for a given key.
  #
  # @params key [String] Key to expire
  # @param db [Symbol] (optional) Which Redis database to expire data from.
  #   Defaults to `:default`
  #
  # @return [true, false] Returns true if value existed in cache and was
  #   succesfully expired. Returns false if value did not exist in cache.
  def expire_cached(db: :default, key:)
    Stockpile::CachedValueExpirer.expire_cached(db: db, key: key)
  end

  # Attempts to fetch a value from cache (for a given key). In case of miss
  # will execute given block of code and cache it's result at the provided
  # key for a specified TTL.
  #
  # @param key [String] Key to use for a value lookup from cache or key
  #   to store value at once it is computed
  # @param db [Symbol] (optional) Which Redis database to cache data in.
  #   Defaults to `:default`
  # @param ttl [Integer] (optional) Time in seconds to expire cache after.
  #   Defaults to Stockpile::DEFAULT_TTL
  #
  # @yield [block] A block of code to be executed in case of cache miss
  #
  # @example Perform cache operation
  #   Stockpile.perform_cached(key: 'meaning_of_life', ttl: 42) { 21 * 2 }
  #
  # @return Returns a result of block execution
  def perform_cached(db: :default, key:, ttl: Stockpile::DEFAULT_TTL, &block)
    Stockpile::CachedValueReader.read_or_yield(
      db: db,
      key: key,
      ttl: ttl,
      &block
    )
  end

  # API to communicate with Redis database backing cache up.
  #
  # @yield [redis]
  #
  # @example Store a value in Redis at given key
  #   Store.redis { |r| r.set('meaning_of_life', 42) }
  #
  # @return Returns a result of interaction with Redis
  def redis(db: :default)
    redis_connections.with(db: db) do |connection|
      yield connection
    end
  end

  # Accessor to connection pool. Defined on top level so it can be memoized
  # on the topmost level
  #
  # @return [Stockpile::RedisConnections] RedisConnections object holding all defined
  #   connection pools
  def redis_connections
    @redis_connections ||= Stockpile::RedisConnectionsFactory.build_connections
  end
end
