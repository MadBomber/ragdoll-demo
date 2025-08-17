source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"

gem "ragdoll", path: "../ragdoll"
gem "ragdoll-rails", path: "../ragdoll-rails"

# Temporary workaround - ragdoll needs debug_me at runtime
gem "debug_me"

gem "propshaft"
gem "pg"
gem "puma"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

gem "view_component"
gem "view_component-contrib"




gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Redis for ActionCable adapter
gem "redis"

gem 'mission_control-jobs'

gem "bootsnap", require: false

gem "kamal", require: false

gem "thruster", require: false



group :development, :test do
  gem 'claude-on-rails'
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "brakeman", require: false

  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "foreman"
  gem "web-console"
  gem "hotwire-livereload"  # Auto-refresh browser on file changes
end
