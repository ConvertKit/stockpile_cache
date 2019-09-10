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

RSpec.describe Stockpile::CachedValueReader do
  after(:each) do
    Stockpile.redis { |r| r.expire('foo', 0) }
  end

  describe '#read_or_yield' do
    it 'fetches result from cache if key is present there' do
      Stockpile.redis { |r| r.set('foo', 1) }
      allow(Stockpile::Executor).to receive(:perform)
      result = Stockpile::CachedValueReader.read_or_yield(key: 'foo', ttl: 1) {}

      expect(Stockpile::Executor).not_to have_received(:perform)
      expect(result).to eq(1)
    end

    it 'offloads work to executor if key is not in cache' do
      allow(Stockpile::Executor).to receive(:perform)
      Stockpile::CachedValueReader.read_or_yield(key: 'foo', ttl: 1) {}

      expect(Stockpile::Executor).to have_received(:perform)
    end
  end
end
