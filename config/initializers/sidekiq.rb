# inside config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  Sidekiq::Scheduler.dynamic = true
  schedule_file = Rails.root.join('config', 'sidekiq.yml')

  if File.exist?(schedule_file)
    schedule_hash = YAML.load_file(schedule_file)

    Sidekiq.schedule = schedule_hash
    Sidekiq::Scheduler.reload_schedule!
  end

  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end
