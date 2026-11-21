require_relative "boot"

require "rails/all"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Areca
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # Kept at 6.0 so app behaviour doesn't change during the Ruby/Rails upgrade.
    # Raise it step by step later (see config/initializers/new_framework_defaults_*.rb).
    config.load_defaults 6.0

    # app/models/datastructures holds top-level classes (e.g. ItemSum), not a
    # Datastructures:: namespace — tell Zeitwerk not to treat it as one.
    Rails.autoloaders.main.collapse(root.join("app/models/datastructures"))

    # audited stores changes as YAML; Rails 7.0.3.1+ only deserializes
    # explicitly permitted classes.
    config.active_record.yaml_column_permitted_classes = [
      Symbol, Date, Time, DateTime, BigDecimal,
      ActiveSupport::TimeWithZone, ActiveSupport::TimeZone,
      ActiveSupport::HashWithIndifferentAccess
    ]

    # Settings in config/environments/* take precedence over those specified here.
  end
end
