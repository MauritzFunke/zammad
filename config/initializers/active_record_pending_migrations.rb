# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

if %w[1 true].include? ENV['RAILS_CHECK_PENDING_MIGRATIONS']
  ActiveRecord::Migration.check_pending!
end
