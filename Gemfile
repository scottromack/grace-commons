source "https://rubygems.org"

require "json"

# The theme is pinned in one place: package.json's jtd-inks. The Tailwind build reads that
# commit from npm and Jekyll reads the same commit from here, so the two cannot differ.
# Gemfile.lock and package-lock.json record the commit; to move it, change package.json,
# then run `npm install` and `bundle update just-the-docs`.
theme = JSON.parse(File.read(File.join(__dir__, "package.json"))).dig("devDependencies", "jtd-inks")
pin = theme.to_s[/#(\h{40})\z/, 1] or abort "package.json: jtd-inks must be pinned to a full commit sha"

gem "just-the-docs", git: "https://github.com/scottromack/jtd-inks.git", ref: pin

gem "base64"
gem "csv"
gem "webrick"

gem "jekyll-include-cache"
gem "jekyll-seo-tag"
gem "jekyll-sitemap"
