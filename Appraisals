# Appraisal matrix for the gem.
#
# These mirror the hand-maintained gemfiles/ used to run the suite against
# multiple ActiveRecord / ActiveJob versions. Generate the lockfiles with:
#
#   bundle exec appraisal install
#
# and run the suite with:
#
#   bundle exec appraisal rspec
#
# Ruby support: 5.2 / 6.0 / 6.1 run under Ruby 2.7; 6.1 / 7.0 / 7.2 run under
# Ruby 3.3. concurrent-ruby is pinned to 1.3.4 for Rails < 7.1 (1.3.5+ drops
# the transitive `logger` require those versions rely on at boot).

appraise "rails-5.2" do
  gem "activerecord", "~> 5.2.0"
  gem "activejob", "~> 5.2.0"
  gem "sqlite3", "~> 1.4"
  gem "concurrent-ruby", "1.3.4"
end

appraise "rails-6.0" do
  gem "activerecord", "~> 6.0.0"
  gem "activejob", "~> 6.0.0"
  gem "sqlite3", "~> 1.4"
  gem "concurrent-ruby", "1.3.4"
end

appraise "rails-6.1" do
  gem "activerecord", "~> 6.1.0"
  gem "activejob", "~> 6.1.0"
  gem "sqlite3", "~> 1.4"
  gem "concurrent-ruby", "1.3.4"
end

appraise "rails-7.0" do
  gem "activerecord", "~> 7.0.0"
  gem "activejob", "~> 7.0.0"
  gem "sqlite3", "~> 1.4"
end

appraise "rails-7.2" do
  gem "activerecord", "~> 7.2.0"
  gem "activejob", "~> 7.2.0"
  gem "sqlite3", ">= 1.4"
end
