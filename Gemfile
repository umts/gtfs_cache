source "https://rubygems.org"
ruby file: ".ruby-version"

gem "activesupport", require: "active_support/all"
gem "puma", require: false
gem "rack"
gem "rubyzip", require: "zip"
gem "sinatra", require: "sinatra/base"

group :development do
  gem "irb", require: false
  gem "rubocop", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "simplecov"
  gem "webmock", require: "webmock/rspec"
end
