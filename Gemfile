source "https://rubygems.org"
ruby file: ".ruby-version"

gem "puma", require: false
gem "rack"
gem "sinatra", require: "sinatra/base"

group :development do
  gem "irb", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "simplecov"
end
