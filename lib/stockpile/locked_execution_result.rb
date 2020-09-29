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
  # == Stockpile::LockedExecutionResult
  #
  # Wrapper containing result of locked execution
  class LockedExecutionResult
    attr_reader :db, :lock_key, :result

    def initialize(db: :default, lock_key:, result:)
      @db = db
      @lock_key = lock_key
      @result = result
    end

    def release_lock
      Stockpile.redis(db: db) { |r| r.expire(lock_key, 0) }
    end

    def success?
      !result.is_a?(Stockpile::FailedLockExecution)
    end
  end
end
