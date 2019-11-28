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

RSpec.describe Stockpile::DefaultRedisConfiguration do
  describe '#configuration' do
    it 'returns an array containing a single hash with connection options' do
      config = Stockpile::DefaultRedisConfiguration.configuration

      expect(config).to be_an(Array)
      expect(config.size).to eq(1)
      expect(config[0]).to be_a(Hash)
      expect(config[0].keys).to match_array(%i[db pool_configuration redis_configuration])
    end
  end

  describe '#redis_configuration' do
    it 'returns a hash containing redis settings' do
      Stockpile.configure { |c| c.sentinels = 'localhost:42' }
      config = Stockpile::DefaultRedisConfiguration.redis_configuration

      expect(config).to be_a(Hash)
      expect(config[:url]).to eq(Stockpile.configuration.redis_url)
      expect(config[:sentinels]).to eq('localhost:42')
    end

    it 'removes nil values' do
      Stockpile.configure { |c| c.sentinels = nil }
      config = Stockpile::DefaultRedisConfiguration.redis_configuration

      expect(Stockpile.configuration.sentinels).to eq(nil)
      expect(config.keys).not_to include(:sentinels)
    end
  end

  describe '#pool_configuration' do
    it 'returns a hash containing pool settings' do
      config = Stockpile::DefaultRedisConfiguration.pool_configuration

      expect(config).to be_a(Hash)
      expect(config[:size]).to eq(Stockpile.configuration.connection_pool)
      expect(config[:timeout]).to eq(Stockpile.configuration.connection_timeout)
    end
  end
end
