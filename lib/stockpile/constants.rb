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
  DEFAULT_CONNECTION_POOL = 100
  DEFAULT_CONNECTION_TIMEOUT = 3
  DEFAULT_LOCK_EXPIRATION = 10
  DEFAULT_REDIS_URL = 'redis://localhost:6379/1'
  DEFAULT_SLUMBER = 2
  DEFAULT_TTL = 60 * 5
  LOCK_PREFIX = 'stockpile_lock::'
  SLUMBER_COOLDOWN = 0.05
  VERSION = '1.0.0'
end
