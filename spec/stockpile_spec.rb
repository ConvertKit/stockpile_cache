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

RSpec.describe Stockpile do
  describe '#configuration' do
    it 'returns configuration object' do
      expect(Stockpile.configuration).to be_kind_of(Stockpile::Configuration)
    end
  end

  describe '#configure' do
    it 'allows to create custom configuration' do
      Stockpile.configure do |c|
        expect(c).to respond_to(:connection_pool=)
        expect(c).to respond_to(:connection_timeout=)
        expect(c).to respond_to(:lock_expiration=)
        expect(c).to respond_to(:redis_url=)
        expect(c).to respond_to(:sentinels=)
        expect(c).to respond_to(:slumber=)
        expect(c).to respond_to(:configuration_file=)
      end
    end
  end

  describe '#expire_cached' do
    it 'relays call to CachedValueExpirer' do
      allow(Stockpile::CachedValueExpirer).to receive(:expire_cached)
      expected_params = { db: :default, key: 'foo' }
      Stockpile.expire_cached(key: 'foo')

      expect(Stockpile::CachedValueExpirer).to have_received(:expire_cached).with(expected_params)
    end
  end

  describe '#perform_cached' do
    it 'relays call to CachedValueReader' do
      allow(Stockpile::CachedValueReader).to receive(:read_or_yield)
      expected_params = { db: :default, key: 'foo', ttl: 1 }
      Stockpile.perform_cached(key: 'foo', ttl: 1)

      expect(Stockpile::CachedValueReader).to have_received(:read_or_yield).with(expected_params)
    end
  end

  describe '#redis' do
    it 'yields control' do
      expect { |b| Stockpile.redis(&b) }.to yield_control
    end
  end

  describe '#redis_connection_pool' do
    it 'returns a ConnectionPool object' do
      pool = Stockpile.redis_connections

      expect(pool).to be(Stockpile::RedisConnections)
    end
  end
end
