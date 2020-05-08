# Stockpile [![Build Status][ci-image]][ci] [![Code Climate][codeclimate-image]][codeclimate] [![Gem Version][version-image]][version]
Stockpile is a simple cache written in Ruby backed by Redis. It has built in
[cache-stampede](https://en.wikipedia.org/wiki/Cache_stampede) (also known as
dog-piling) protection and support for multiple Redis servers.

Can be used with any Ruby or Ruby on Rails project. Can be used as a replacement for
existing Ruby on Rails cache.

Intended as a heavy usage cache to prevent concurrent execution of code when
cache is expired that will lead to congestion collapse of your systems.

Upon caching serializes cached value using [Oj](https://github.com/ohler55/oj)
gem. While reading value from cache will deserialize value from cache using same
gem.

## How it works
When `perform_cached` method is invoked with a key and a block of code as
arguments Stockpile will attempt to fetch value from cache using given key. If
no value is returned it will set a lock deferring all other requests for given
key (for specified amount of time) and run provided block of code and storing
it's return value at the key. After that a lock will be released allowing other
requests to fetch their values from cache.

In case there is a cache miss and an active execution lock for a given key is
present request will go into slumber for 2 seconds (configurable by
`STOCKPILE_SLUMBER` environment variable or by calling `slumber` method on
configuration object). During slumber request will keep trying to read value
from cache and if no result is returned during that time cache will be bypassed
and value will be computed by executing passed in block.

## Installation
Add the following line to your Gemfile:

```
gem 'stockpile_cache'
```
And run `bundle` from your shell.

To install gem manually run from your shell:

```
gem install stockpile_cache
```

## Requirements
Only requirement to run this gem is [Redis](https://redis.io/). Other than that
it is not dependant on any other framework or system.

## Configration
The only thing you need to set up is URL of your Redis server. You can do this
by either setting `STOCKPILE_REDIS_URL` environment variable or by executing
following code during runtime. For Ruby on Rails create
`config/initializers/stockpile.rb` file and put the following code in there:

```
Stockpile.configure do |configuration|
  configuration.redis_url = <REDIS_URL>
end
```

There are two ways to configure Stockpile: using environment variables or
invoking configuration block during runtime.

Following settings are supported:

| Variable | Method | Settings |
| ------------- | ------------- | ------------- |
| `STOCKPILE_CONNECTION_POOL` | `connection_pool` | Redis connection pool size to share amongst the fibers or threads in your Ruby. Defaults to `100`. |
| `STOCKPILE_CONNECTION_TIMEOUT` | `connection_timeout`  | How long to wait for a connection from connection pool to become available (in seconds). Defaults to `3`. |
| `STOCKPILE_LOCK_EXPIRATION` | `lock_expiration` | Time to keep execution lock alive (in seonds). Defaults to `10`. |
| `STOCKPILE_REDIS_URL` | `redis_url` | URL of your Redis server that will be used for caching. Defaults to `redis://localhost:6379/1`. |
| `STOCKPILE_REDIS_SENTINELS` | `sentinels` | (optional) Comma separated list of Sentinels IPs for Redis. Defaults to `nil`. Example value: `8.8.8.8:42,8.8.4.4:42`. |
| `STOCKPILE_SLUMBER` | `slumber` | Timeout (in seconds) for stampede protection lock. After timeout passed in code will be executed instead of reading a value from cache. Defaults to `2`. |
| `STOCKPILE_CONFIGURATION_FILE` | `configuration_file` | (optional) `.yml` configuration file to read connection information from. See [Multiple Database](#multiple-database). |

## Usage
To use simply wrap your code into `perform_cached` block:

```
Stockpile.perform_cached(key: 'meaning_of_life', ttl: 42) do
  21 + 21
end
```

`perform` method accepts 4 named arguments:

| Argument | Meaning |
| ------------- | ------------- |
| `key` | Pointer in cache by which a value will be either looked up or stored in cache once code provided in block is executed. |
| `ttl` | (optional) Time in seconds for which a cached value will be stored. Defaults to 300 seconds (5 minutes). |
| `db` | (optional) Name of the Redis database to cache value in. Defaults to `:default` |
| `&block` | Block of code to execute; it's return value will be stored in cache. |

### Multiple Database
Stockpile comes with a support for multiple databases. A word of caution: unless
you have very good reason to run multiple databases within single instance of
Redis server you probably should avoid doing so as you will not see any performance
improvements in doing so.

To allow multi-database support you have to do two things. First you have to set
`configuration_file` setting to point at `.yml` containing your configuration.
You can do so by either setting a `STOCKPILE_CONFIGURATION_FILE` environment
variable or by executing a configuration block during runtime (for Rails create
`config/initializers/stockpile.rb` with following content):

```
Stockpile.configure do |configuration|
  configuration.configuration_file = <PATH/TO/FILE>
end
```

Second thing to do is to create a `.yml` configuration file. It has to have at
least one database definition. Providing `sentinels` is optional. Everything
else is mandatory:

```
---
master:
  url: 'redis://redis-1-host:6379/1'
  sentinels: '8.8.8.8:42,8.8.4.4:42'
  pool_options:
    size: 5
    timeout: 5

commander:
  url: 'redis://redis-2-host:6379/1'
  pool_options:
    size: 5
    timeout: 5
```

To query different databases provide a corresponding `db:` param with
`perform_cached` method:

```
Stockpile.perform_cached(db: :master, key: 'meaning_of_life', ttl: 42) do
  21 + 21
end

Stockpile.perform_cached(db: :commander, key: 'meaning_of_life', ttl: 21) do
  21
end
```

If you do not provide a `db:` param then a `:default` database will be used; if
you do not define it in a configuration file your request will error out.

Using `configuration_file` setting will make Stockpile ignore all other
Redis connection related settings and it will read configuration from `.yml`
file instead.

### Compression of Cached Content
Stockpile optionally supports compression of cached content; you will not see
much benefit from compressing small strings but once you start caching bigger
payloads like fragments of HTML you could see some improvements by using
compression. To use compression you will have to use configuration file set by
`STOCKPILE_CONFIGURATION_FILE`.

To enable compression you have to do two things. First you have to set
`configuration_file` setting to point at `.yml` containing your configuration.
You can do so by either setting a `STOCKPILE_CONFIGURATION_FILE` environment
variable or by executing a configuration block during runtime (for Rails create
`config/initializers/stockpile.rb` with following content):

```
Stockpile.configure do |configuration|
  configuration.configuration_file = <PATH/TO/FILE>
end
```

Second thing to do is to create a `.yml` configuration file. It has to have at
least one database definition. Providing `sentinels` and `compression` is
optional. Everything else is mandatory:


```
---
master:
  url: 'redis://redis-1-host:6379/1'
  sentinels: '8.8.8.8:42,8.8.4.4:42'
  compression: true
  pool_options:
    size: 5
    timeout: 5
```

From that point everything that will be cached in `master` database will be
compressed.

## Caveats
There is no timeout or rescue set for code you will be running through the cache. If
you need to do either you have to handle it outside of Stockpile.

Locks are never set indefinitely and by default will expire after 10 seconds
allowing next request to trigger cache recalculation. Lock duration is
configurable by either setting `STOCKPILE_LOCK_EXPIRATION` environment variable
or by calling `slumber` method on configuration object.

While there is an active lock for the key each request trying to read that key
will wait in slumber for 2 seconds (configurable by `STOCKPILE_SLUMBER`
environment variable or by calling `slumber` method on configuration object) and
will bypass cache after that if no value will be set in that time.

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rspec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at
https://github.com/ConvertKit/stockpile_cache. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License
The gem is available as open source under the terms of the
[Apache License Version 2.0] (http://www.apache.org/licenses/LICENSE-2.0).

## Code of Conduct
Everyone interacting in the Stockpile project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/ConvertKit/stockpile_cache/blob/master/CODE_OF_CONDUCT.md).

[ci]: https://circleci.com/gh/ConvertKit/stockpile_cache
[ci-image]: https://circleci.com/gh/ConvertKit/stockpile_cache.svg?style=svg
[codeclimate]: https://codeclimate.com/github/ConvertKit/stockpile_cache/maintainability
[codeclimate-image]: https://api.codeclimate.com/v1/badges/f9ca3b6dda3b492b125e/maintainability
[version]: https://badge.fury.io/rb/stockpile_cache
[version-image]: https://badge.fury.io/rb/stockpile_cache.svg
