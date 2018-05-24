Sidekiq.configure_server do |config|
  config.redis = if Rails.env.production?
                   { url: ENV['REDIS_URL'] }
                 else
                   { url: 'redis://localhost:6379/5' }
                 end
end

Sidekiq.configure_client do |config|
  config.redis = if Rails.env.production?
                   { url: ENV['REDIS_URL'] }
                 else
                   { url: 'redis://localhost:6379/5' }
                 end
end
