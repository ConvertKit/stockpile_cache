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

RSpec.describe Stockpile::LockedExecutionResult do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '#release_lock' do
    it 'expires lock at provided key' do
      Stockpile.redis { |r| r.set('foo', 1) }
      result = Stockpile::LockedExecutionResult.new(lock_key: 'foo', result: '')
      result.release_lock

      expect(Stockpile.redis { |r| r.get('foo') }).to be_nil
    end
  end

  describe '#success?' do
    it 'returns true unless result is a FailedLock' do
      result = Stockpile::LockedExecutionResult.new(lock_key: '', result: 'foo')

      expect(result.success?).to eq(true)
    end

    it 'returns false if result is a FailedLock' do
      lock = Stockpile::FailedLockExecution.new
      result = Stockpile::LockedExecutionResult.new(lock_key: '', result: lock)

      expect(result.success?).to eq(false)
    end
  end
end
