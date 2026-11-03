# Site content comes from db/seeds/content/*.rb (generated from the local database by
# `bin/rails content_seed:dump`). Loading it REPLACES the content tables and their images,
# so the target database ends up identical to the one the files were dumped from.
# Leads, their files and users are kept.
if ContentSeed.available?
  puts "== Content (db/seeds/content)"
  ContentSeed.load!
else
  puts "== Content (prototype defaults; db/seeds/content not found)"
  load Rails.root.join("db/seeds/defaults.rb")
end

puts "== Admin user"
if User.none?
  email = ENV.fetch("ADMIN_EMAIL", "admin@mazaya.local")
  password = ENV.fetch("ADMIN_PASSWORD", "mazaya-admin-2026")
  User.create!(name: "Admin", email: email, password: password, role: "admin")
  puts "   created #{email} / #{password}  (change it from /admin/users)"
end

Setting.bump_content_version!
Rails.cache.clear
puts "== Done (restart the app so every process reloads its translations)"
