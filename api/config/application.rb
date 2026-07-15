require_relative "boot"

require "rails"
require "action_controller/railtie"
require "active_job/railtie"

Bundler.require(*Rails.groups)

module WorkverseDocumentAi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq
    config.autoload_paths << Rails.root.join("app/services")
  end
end
