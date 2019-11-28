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
  # == Stockpile::Lock
  #
  # Attempts to set up exclusive lock to execute a block of code. Returns
  # Stockpile::LockedExcutionResult holding result of execution. If lock
  # can not be established (someone else is executing the code) then
  # Stockpile::LockedExcutionResult will hold Stockpile::FailedLockExecution
  # as a result of execution
  class Lock
    attr_reader :db, :lock_key

    def self.perform_locked(db: :default, lock_key:, &block)
      new(db, lock_key).perform_locked(&block)
    end

    def initialize(db, lock_key)
      @db = db
      @lock_key = lock_key
    end

    def perform_locked(&block)
      if lock
        successful_execution(&block)
      else
        failed_execution
      end
    end

    private

    def failed_execution
      Stockpile::LockedExcutionResult.new(db: db, result: failed_lock, lock_key: lock_key)
    end

    def failed_lock
      Stockpile::FailedLockExecution.new
    end

    def lock
      Stockpile.redis(db: db) { |r| r.set(lock_key, 1, nx: true, ex: Stockpile.configuration.lock_expiration) }
    end

    def successful_execution
      Stockpile::LockedExcutionResult.new(db: db, result: yield, lock_key: lock_key)
    end
  end
end
