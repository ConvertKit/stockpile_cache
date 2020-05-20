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
  # == Stockpile::Executor
  #
  # Executes passed in block of code and writes computed result into cache
  # with an expiration of a given TTL. If execution is locked will wait for
  # value to appear in cache instead. Will timeout after given amount of time
  # and will execute block if no value can be read from cache.
  class Executor
    attr_reader :db, :key, :ttl

    def self.perform(db: :default, key:, ttl:, &block)
      new(db, key, ttl).perform(&block)
    end

    def initialize(db, key, ttl)
      @db = db
      @key = key
      @ttl = ttl
    end

    def perform(&block)
      if execution(&block).success?
        cache_and_release_execution
      else
        wait_for_cache_or_yield(&block)
      end
    end

    private

    def compress?
      RedisConnections.compression?(db: db)
    end

    def execution
      @execution ||= Stockpile::Lock.perform_locked(db: db, lock_key: lock_key) do
        yield
      end
    end

    def cache_and_release_execution
      Stockpile::Cache.set(
        db: db,
        key: key,
        payload: execution.result,
        ttl: ttl,
        compress: compress?
      )

      execution.release_lock
      execution.result
    end

    def lock_key
      Stockpile::LOCK_PREFIX + key
    end

    def wait_for_cache_or_yield
      Timeout.timeout(Stockpile.configuration.slumber) do
        Stockpile::Cache.get_deferred(db: db, key: key, compress: compress?)
      end
    rescue Timeout::Error
      yield
    end
  end
end
