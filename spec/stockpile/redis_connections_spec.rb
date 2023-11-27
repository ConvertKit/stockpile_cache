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

RSpec.describe Stockpile::RedisConnections do
  describe '#compression?' do
    it 'gets value of instance variable' do
      Stockpile::RedisConnections.instance_variable_set(:@foo_compression, 42)

      expect(Stockpile::RedisConnections.compression?(db: 'foo')).to eq(42)
    end
  end

  describe '#include?' do
    it 'returns true if the instance variable has been set' do
      Stockpile::RedisConnections.instance_variable_set(:@foo, Object.new)

      expect(Stockpile::RedisConnections.include?(db: 'foo')).to eq(true)
    end

    it 'returns false if the instance variable has not been set' do
      expect(Stockpile::RedisConnections.include?(db: 'bar')).to eq(false)
    end
  end

  describe '#with' do
    class Klazz
      def self.with
        yield
      end
    end

    it 'gets an instance variable and yields connection to it' do
      allow(Klazz).to receive(:with).and_call_original
      Stockpile::RedisConnections.instance_variable_set(:@foo, Klazz)
      Stockpile::RedisConnections.with(db: :foo) {}

      expect(Klazz).to have_received(:with)
    end
  end
end
