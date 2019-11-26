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

RSpec.describe Stockpile::Executor do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '.perform' do
    it 'is a shortcut for constructor with method call' do
      executor = Stockpile::Executor.new(:default, 'foo', 1)
      allow(Stockpile::Executor).to receive(:new).and_return(executor)
      allow(executor).to receive(:perform)
      Stockpile::Executor.perform(key: 'foo', ttl: 1)

      expect(executor).to have_received(:perform)
    end
  end

  describe '#perform' do
    it 'returns executed block (without value being cached)' do
      result = Stockpile::Executor.perform(key: 'foo', ttl: 60) { 1 + 1 }

      expect(result).to eq(2)
    end

    it 'sets value in cache after execution' do
      result = Stockpile::Executor.perform(key: 'foo', ttl: 60) { 1 + 1 }
      cached_value = Stockpile.redis { |r| r.get('foo') }

      expect(result.to_s).to eq(cached_value)
    end

    it 'will wait for cached value if execution is locked' do
      Stockpile.redis { |r| r.setnx(Stockpile::LOCK_PREFIX + 'foo', 1) }

      thread = Thread.new do
        Stockpile::Executor.perform(key: 'foo', ttl: 60) { 1 + 1 }
      end

      Stockpile.redis { |r| r.set('foo', 42) }

      expect(thread.alive?).to be(true)

      thread.join
      Stockpile.redis { |r| r.expire(Stockpile::LOCK_PREFIX + 'foo', 0) }

      expect(thread.value).to eq(42)
    end
  end
end
