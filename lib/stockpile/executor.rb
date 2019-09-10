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
    attr_reader :key, :ttl

    def self.perform(key:, ttl:, &block)
      new(key, ttl).perform(&block)
    end

    def initialize(key, ttl)
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

    def execution
      @execution ||= Stockpile::Lock.perform_locked(lock_key: lock_key) do
        yield
      end
    end

    def cache_and_release_execution
      Stockpile::Cache.set(
        key: key,
        payload: execution.result,
        ttl: ttl
      )

      execution.release_lock
      execution.result
    end

    def lock_key
      Stockpile::LOCK_PREFIX + key
    end

    def wait_for_cache_or_yield
      Timeout.timeout(Stockpile.configuration.slumber) do
        Stockpile::Cache.get_deferred(key: key)
      end
    rescue Timeout::Error
      yield
    end
  end
end
