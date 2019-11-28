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

module Stockpile
  # == Stockpile::RedisConnections
  #
  # Wrapper around pools of Redis connections to allow multiple
  # Redis database support
  module RedisConnections
    module_function

    def with(db:)
      instance_variable_get("@#{db}".to_sym).with do |connection|
        yield connection
      end
    end
  end
end
