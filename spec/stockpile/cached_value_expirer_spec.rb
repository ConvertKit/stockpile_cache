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

RSpec.describe Stockpile::CachedValueExpirer do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '#expire_cached' do
    it 'expires cached values and returns true' do
      Stockpile.redis { |r| r.set('foo', 1) }

      expect(Stockpile.redis { |r| r.get('foo') }).to eq('1')

      result = Stockpile::CachedValueExpirer.expire_cached(key: 'foo')

      expect(result).to eq(true)
      expect(Stockpile.redis { |r| r.get('foo') }).to eq(nil)
    end

    it 'returns false if value is not present in cache' do
      expect(Stockpile.redis { |r| r.get('foo') }).to eq(nil)

      result = Stockpile::CachedValueExpirer.expire_cached(key: 'foo')

      expect(result).to eq(false)
    end
  end
end
