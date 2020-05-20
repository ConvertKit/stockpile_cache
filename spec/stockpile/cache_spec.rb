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

RSpec.describe Stockpile::Cache do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '#get' do
    it 'returns value from cache' do
      Stockpile.redis { |r| r.set('foo', 1) }

      expect(Stockpile::Cache.get(key: 'foo')).to eq(1)
    end

    it 'properly serializes object from cache' do
      object = { a: 1, b: [2, 3] }
      payload = Oj.dump(object)
      Stockpile.redis { |r| r.set('foo', payload) }

      expect(Stockpile::Cache.get(key: 'foo')).to eq(object)
    end

    it 'properly compresses and base64 encodes object if compression is true' do
      string = 'What is love?'
      payload = Base64.encode64(Zlib::Deflate.deflate(Oj.dump(string)))
      Stockpile.redis { |r| r.set('foo', payload) }

      expect(Stockpile::Cache.get(key: 'foo', compress: true)).to eq(string)
    end
  end

  describe '#get_deferred' do
    it 'will block cache fetch until value is set' do
      thread = Thread.new { Stockpile::Cache.get_deferred(key: 'foo') }

      expect(thread.alive?).to be(true)

      Stockpile.redis { |r| r.set('foo', 1) }

      expect(thread.value).to eq(1)
      expect(thread.alive?).to be(false)
    end
  end

  describe '#set' do
    let(:simple_payload) { { key: 'foo', payload: 1, ttl: 60 } }
    let(:object_payload) { { key: 'foo', payload: { a: 1 }, ttl: 60 } }

    it 'writes value into redis (with expiration)' do
      Stockpile::Cache.set(simple_payload)

      expect(Stockpile.redis { |r| r.get('foo') }).to eq('1')
      expect(Stockpile.redis { |r| r.ttl('foo') }).to be_between(50, 60)
    end

    it 'properly deserializes object' do
      Stockpile::Cache.set(object_payload)

      expect(Stockpile.redis { |r| r.get('foo') }).to eq('{":a":1}')
    end

    it 'compresses and base64 encodes object if compression is true' do
      payload = { key: 'foo', payload: 42, compress: true, ttl: 60 }
      Stockpile::Cache.set(payload)
      expected = Base64.encode64(Zlib::Deflate.deflate(Oj.dump(42)))

      # Base64.encode64(Zlib::Deflate.deflate(Oj.dump(42))) => eJwzMQIAAJwAZw==\n
      # Inserting raw value in here instead of computing it in the test on purpose
      # so we can set expectations around what should be returned and not what current
      # code returns
      expect(Stockpile.redis { |r| r.get('foo') }).to eq(expected)
    end
  end
end
