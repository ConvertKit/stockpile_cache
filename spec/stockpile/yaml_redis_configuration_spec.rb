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

RSpec.describe Stockpile::YamlRedisConfiguration do
  let(:parsed_yaml) do
    {
      master: {
        'url' => 'foo',
        'sentinels' => 'localhost:42',
        'pool_options' => {
          'size' => 5,
          'timeout' => 5
        }
      },
      commander: {
        'url' => 'bar',
        'pool_options' => {
          'size' => 10,
          'timeout' => 10
        }
      }
    }
  end

  before do
    allow(Stockpile::YamlRedisConfiguration).to receive(:parsed_configuration)
      .and_return(parsed_yaml)
  end

  describe '#configuration' do
    it 'returns an array containing a multiple hashes with connection options' do
      config = Stockpile::YamlRedisConfiguration.configuration

      expect(config).to be_an(Array)
      expect(config.size).to eq(2)
      expect(config[0]).to be_a(Hash)
      expect(config[0].keys).to match_array(%i[db pool_configuration redis_configuration])
    end

    it 'parses a redis connection (with sentinels)' do
      config = Stockpile::YamlRedisConfiguration.configuration
      first_redis_config = { url: 'foo', sentinels: [{ host: 'localhost', port: 42 }] }
      second_redis_config = { url: 'bar' }

      expect(config[0][:redis_configuration]).to eq(first_redis_config)
      expect(config[1][:redis_configuration]).to eq(second_redis_config)
    end

    it 'parses connection pool' do
      config = Stockpile::YamlRedisConfiguration.configuration
      first_pool_config = { size: 5, timeout: 5 }
      second_pool_config = { size: 10, timeout: 10 }

      expect(config[0][:pool_configuration]).to eq(first_pool_config)
      expect(config[1][:pool_configuration]).to eq(second_pool_config)
    end
  end
end
