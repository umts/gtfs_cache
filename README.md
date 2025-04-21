# gtfs_cache

A simple webserver that makes the PVTA's GTFS and GTFS Realtime datasets available publicly.

When the server is booted it spawns a background thread (implemented as a puma plugin) that periodically fetches and
caches responses from the original data sources ([the PVTA itself](https://www.pvta.com/g_trans/) for GTFS,
[Swiftly](https://www.goswift.ly) for GTFS Realtime).

These cached responses are then forwarded to requests made to the server itself.

This gets us around various access control pain points (CORS for the PVTA, API keys/rate limits for Swiftly) when
using these datasets in our other applications.

## Development

The application is built on the Sinatra framework. It is recommended you use rbenv to install/manage ruby.

### Setup

1) Install ruby. (`rbenv install`)
2) Run the setup script. (`script/setup`)

### Scripts

* Run `bin/rspec` to run the tests.
* Run `bin/rubocop` to run the linter.
* Run `script/console` for an interactive prompt that will allow you to experiment.
* Run `script/server` to run the development server.
* Run `script/setup` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umts/gtfs_cache.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
