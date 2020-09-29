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

RSpec.describe Stockpile::Lock do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  class LockSpecKlass
    def self.perform; end
  end

  describe '.perform' do
    it 'is a shortcut for constructor with method call' do
      lock = Stockpile::Lock.new(:default, 'foo')
      allow(Stockpile::Lock).to receive(:new).and_return(lock)
      allow(lock).to receive(:perform_locked)
      Stockpile::Lock.perform_locked(lock_key: 'foo') {}

      expect(lock).to have_received(:perform_locked)
    end
  end

  describe '#perform_locked' do
    let(:lock) { Stockpile::Lock.new(:default, 'foo') }

    after(:each) do
      Stockpile.redis { |r| r.expire('foo', 0) }
    end

    it 'returns object containing execution result' do
      execution = lock.perform_locked { 'bar' }

      expect(execution).to be_a(Stockpile::LockedExecutionResult)
      expect(execution.result).to eq('bar')
    end

    it 'returns object containing lock key' do
      execution = lock.perform_locked { 'bar' }

      expect(execution).to be_a(Stockpile::LockedExecutionResult)
      expect(execution.lock_key).to eq('foo')
    end

    it 'does not releases lock after execution' do
      lock.perform_locked do
        expect(Stockpile.redis { |r| r.get('foo') }).to eq('1')
      end

      expect(Stockpile.redis { |r| r.get('foo') }).to eq('1')
    end

    it 'will not execute code if lock exists and will return error class' do
      Stockpile.redis { |r| r.set('foo', 1) }
      allow(LockSpecKlass).to receive(:perform)
      execution = lock.perform_locked do
        LockSpecKlass.perform
      end

      expect(LockSpecKlass).not_to have_received(:perform)
      expect(execution.result).to be_a(Stockpile::FailedLockExecution)
    end

    it 'will not release lock if it already exists' do
      Stockpile.redis { |r| r.set('foo', 1) }
      lock.perform_locked {}
      lock = Stockpile.redis { |r| r.get('foo') }

      expect(lock).to eq('1')
    end

    it 'will set lock that degrades over time' do
      Stockpile::Lock.perform_locked(lock_key: 'foo') do
        lock_key_ttl = Stockpile.redis { |r| r.ttl('foo') }
        expect(lock_key_ttl).to be_between(1, 10)
      end
    end
  end
end
