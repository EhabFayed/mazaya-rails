# frozen_string_literal: true

namespace :content_seed do
  desc "Write the current site content to db/seeds/content/*.rb and its files to db/seeds/files/"
  task dump: :environment do
    ContentSeed.dump!
  end
end
