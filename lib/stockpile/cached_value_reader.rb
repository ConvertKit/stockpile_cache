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
  # == Stockpile::CachedValueReader
  #
  # Service class to wrap decision point of wether a value should be
  # returned from cache or computed and stored in cache
  module CachedValueReader
    module_function

    def read_or_yield(db: :default, key:, ttl:, &block)
      if (result = Stockpile::Cache.get(db: db, key: key, compress: RedisConnections.compression?(db: db)))
        result
      else
        Stockpile::Executor.perform(db: db, key: key, ttl: ttl, &block)
      end
    end
  end
end
