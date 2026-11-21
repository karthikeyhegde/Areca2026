source "https://rubygems.org"

ruby "4.0.9"

gem "rails", "~> 8.1.4"

# Database
gem "mysql2", "~> 0.5.7"

# Web server
gem "puma", ">= 6.0"

# Assets: Sprockets serves app/assets (Chart.min.js, images);
# Shakapacker (successor of Webpacker) builds app/javascript packs.
gem "sprockets-rails"
gem "shakapacker", "10.3.2" # must match the npm "shakapacker" version in package.json

gem "jbuilder"
# image_processing removed: the app has no Active Storage images, and its
# ruby-vips dependency crashes Rails on boot when libvips isn't installed.

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "bcrypt", "~> 3.1"

# No longer part of Ruby's default gems (Ruby 3.4+); used by script/*.rb
gem "csv"

# Excel export (caxlsx is the maintained fork of axlsx)
gem "caxlsx", "~> 4.1"
gem "caxlsx_rails", "~> 0.7"

gem "exception_notification", "~> 5.0"
gem "audited", "~> 5.8"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :development do
  gem "web-console"
  gem "rubycritic", require: false
  gem "traceroute"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
