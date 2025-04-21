source "https://rubygems.org"
ruby file: ".ruby-version"

gem "activesupport", require: "active_support/all"
gem "puma", require: false
gem "rack"
gem "sinatra", require: "sinatra/base"

group :development do
  gem "irb", require: false
  gem "kamal", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "simplecov"
  gem "timecop"
  gem "webmock", require: "webmock/rspec"
end
