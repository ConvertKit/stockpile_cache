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

RSpec.describe Stockpile::Configuration do
  it 'sets @connection_pool to deafult value' do
    config = Stockpile::Configuration.new

    expect(config.connection_pool).to eq(Stockpile::DEFAULT_CONNECTION_POOL)
  end

  it 'sets @connection_pool to value from ENV variable' do
    ENV['STOCKPILE_CONNECTION_POOL'] = '42'
    config = Stockpile::Configuration.new

    expect(config.connection_pool).to eq(42)
  end

  it 'sets @connection_timeout to deafult value' do
    config = Stockpile::Configuration.new

    expect(config.connection_timeout).to eq(Stockpile::DEFAULT_CONNECTION_TIMEOUT)
  end

  it 'sets @connection_timeout to value from ENV variable' do
    ENV['STOCKPILE_CONNECTION_TIMEOUT'] = '42'
    config = Stockpile::Configuration.new

    expect(config.connection_timeout).to eq(42)
  end

  it 'sets @lock_expiration to default value' do
    config = Stockpile::Configuration.new

    expect(config.lock_expiration).to eq(Stockpile::DEFAULT_LOCK_EXPIRATION)
  end

  it 'sets @lock_expiration to value from ENV variable' do
    ENV['STOCKPILE_LOCK_EXPIRATION'] = '42'
    config = Stockpile::Configuration.new

    expect(config.lock_expiration).to eq(42)
  end

  it 'sets @redis_url to default value if no ENV variable is set' do
    config = Stockpile::Configuration.new

    expect(config.redis_url).to eq(Stockpile::DEFAULT_REDIS_URL)
  end

  it 'sets @redis_url to value from ENV variable' do
    ENV['STOCKPILE_REDIS_URL'] = 'foobar'
    config = Stockpile::Configuration.new

    expect(config.redis_url).to eq('foobar')
  end

  it 'sets @slumber to default value if no ENV variable is set' do
    config = Stockpile::Configuration.new

    expect(config.slumber).to eq(Stockpile::DEFAULT_SLUMBER)
  end

  it 'sets @slumber to value from ENV variable' do
    ENV['STOCKPILE_SLUMBER'] = '42'
    config = Stockpile::Configuration.new

    expect(config.slumber).to eq(42)
  end

  it 'sets @sentinels to empty array if no ENV variable is set' do
    config = Stockpile::Configuration.new

    expect(config.sentinels).to eq([])
  end

  it 'parses @sentinels from provided values' do
    ENV['STOCKPILE_REDIS_SENTINELS'] = '1.1.1.1:42'
    config = Stockpile::Configuration.new

    expect(config.sentinels).to eq([{ host: '1.1.1.1', port: 42 }])
  end
end
