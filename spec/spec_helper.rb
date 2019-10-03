require 'safe'
require 'fakeredis'
require 'json'
require 'pry'
require 'pry-byebug'
require 'bundler'

Bundler.require :default, :development, :test

Combustion.initialize! :active_record do
  config.active_record.sqlite3.represent_boolean_as_integer = true
end

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = nil

class Prepare < SAFE::Job; end
class FetchFirstJob < SAFE::Job; end
class FetchSecondJob < SAFE::Job; end
class PersistFirstJob < SAFE::Job; end
class PersistSecondJob < SAFE::Job; end
class NormalizeJob < SAFE::Job; end
class BobJob < SAFE::Job; end

class MonitorableMock < ActiveRecord::Base; end

SAFEFILE = Pathname.new(__FILE__).parent.join("Safefile")

class TestWorkflow < SAFE::Workflow
  def configure(args=nil)
    link(args) if args.respond_to?(:id)

    run Prepare, params: { some_id: args }

    run NormalizeJob

    run FetchFirstJob,   after: Prepare
    run FetchSecondJob,  after: Prepare, before: NormalizeJob

    run PersistFirstJob, after: FetchFirstJob, before: NormalizeJob
  end
end

class ParameterTestWorkflow < SAFE::Workflow
  def configure(param)
    run Prepare if param
  end
end

class Redis
  def publish(*)
  end
end

REDIS_URL = "redis://localhost:6379/12"

module SAFEHelpers
  def redis
    @redis ||= Redis.new(url: REDIS_URL)
  end

  def perform_one
    job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
    if job
      SAFE::Worker.new.perform(*job[:args])
      ActiveJob::Base.queue_adapter.performed_jobs << job
      ActiveJob::Base.queue_adapter.enqueued_jobs.shift
    end
  end

  def jobs_with_id(jobs_array)
    jobs_array.map {|job_name| job_with_id(job_name) }
  end

  def job_with_id(job_name)
    /#{job_name}|(?<identifier>.*)/
  end
end

RSpec::Matchers.define :have_jobs do |flow, jobs|
  match do |actual|
    expected = jobs.map do |job|
      hash_including(args: include(flow, job))
    end
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to match_array(expected)
  end

  failure_message do |actual|
    "expected queue to have #{jobs}, but instead has: #{ActiveJob::Base.queue_adapter.enqueued_jobs.map{ |j| j[:args][1]}}"
  end
end

RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  config.include SAFEHelpers

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus

  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs

    SAFE.configure do |config|
      config.redis_url = REDIS_URL
      config.safefile = SAFEFILE
    end
  end


  config.after(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
    redis.flushdb
  end
end
