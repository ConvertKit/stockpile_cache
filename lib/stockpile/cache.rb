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
  # == Stockpile::Cache
  #
  # Wrapper around Stockpile.redis used for writing and reading from it; handles
  # serialization and deserialization of data upon writes and reads.
  module Cache
    module_function

    def get(db: :default, key:)
      value_from_cache = Stockpile.redis(db: db) { |r| r.get(key) }
      Oj.load(value_from_cache) if value_from_cache
    end

    def get_deferred(db: :default, key:)
      sleep(Stockpile::SLUMBER_COOLDOWN) until Stockpile.redis(db: db) { |r| r.exists(key) }
      value_from_cache = Stockpile.redis(db: db) { |r| r.get(key) }
      Oj.load(value_from_cache)
    end

    def set(db: :default, key:, payload:, ttl:)
      payload = Oj.dump(payload)
      Stockpile.redis(db: db) { |r| r.set(key, payload) }
      Stockpile.redis(db: db) { |r| r.expire(key, ttl) }
    end
  end
end
