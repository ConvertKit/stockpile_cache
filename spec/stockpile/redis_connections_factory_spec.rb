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

RSpec.describe Stockpile::RedisConnectionsFactory do
  let(:configuration) do
    [{
      db: :master,
      pool_configuration: { size: 10, timeout: 10 },
      redis_configuration: { url: 'localhost' }
    }]
  end

  describe '#build_connections' do
    it 'returns Stockpile::RedisConnections' do
      connections = Stockpile::RedisConnectionsFactory.build_connections

      expect(connections).to be(Stockpile::RedisConnections)
    end

    it 'goes through configuration and builds connections' do
      allow(Redis).to receive(:new)
      allow(Stockpile::RedisConnectionsFactory).to receive(:configuration).and_return(configuration)
      connections = Stockpile::RedisConnectionsFactory.build_connections
      pool = connections.instance_variable_get(:@master)

      expect(pool).to be_a(ConnectionPool)
      expect(pool.size).to eq(10)
    end
  end

  describe '#configuration' do
    it 'prefers YAML buildout if file is present' do
      allow(Stockpile::YamlRedisConfiguration).to receive(:configuration)
      allow(Stockpile).to receive_message_chain(
        :configuration,
        :configuration_file
      ).and_return('file.yml')

      Stockpile::RedisConnectionsFactory.configuration

      expect(Stockpile::YamlRedisConfiguration).to have_received(:configuration)
    end

    it 'falls back to default configuration without file' do
      allow(Stockpile::DefaultRedisConfiguration).to receive(:configuration)
      allow(Stockpile).to receive_message_chain(
        :configuration,
        :configuration_file
      ).and_return(nil)

      Stockpile::RedisConnectionsFactory.configuration

      expect(Stockpile::DefaultRedisConfiguration).to have_received(:configuration)
    end
  end

  describe '#process_sentinels' do
    it 'builds out sentinels out of passed in string' do
      sentinels = 'localhost:42,localhost:24'
      parsed = Stockpile::RedisConnectionsFactory.process_sentinels(sentinels: sentinels)
      expected = [
        { host: 'localhost', port: 42 },
        { host: 'localhost', port: 24 }
      ]

      expect(parsed).to eq(expected)
    end
  end
end
