# frozen_string_literal: true

# Copyright 2022 ConvertKit, LLC
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

RSpec.describe Stockpile::CachedValueRenewer do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '#renew_cached' do
    it 'expires cached values and returns true' do
      Stockpile.redis { |r| r.set('foo', 1, ex: 10) }

      expect(Stockpile.redis { |r| r.get('foo') }).to eq('1')
      expect(Stockpile.redis { |r| r.ttl('foo') }).to be <= 10

      result = Stockpile::CachedValueRenewer.renew_cached(key: 'foo', ttl: 100)

      expect(result).to eq(true)
      ttl = Stockpile.redis { |r| r.ttl('foo') }
      # It's possible that we've paused for ... some amount of time since
      # setting the TTL, so it might not literally be `100` when we run specs,
      # but should be close.
      expect(ttl).to be > 10
      expect([100, 99, 98]).to include(ttl)
    end

    it 'returns false if value is not present in cache' do
      expect(Stockpile.redis { |r| r.get('foo') }).to eq(nil)

      result = Stockpile::CachedValueRenewer.renew_cached(key: 'foo', ttl: 100)

      expect(result).to eq(false)
    end
  end
end
