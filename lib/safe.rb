require "bundler/setup"
require "active_record"

require "graphviz"
require "hiredis"
require "pathname"
require "redis"
require "securerandom"
require "multi_json"

require "safe/json"
require "safe/cli"
require "safe/cli/overview"
require "safe/graph"
require "safe/client"
require "safe/configuration"
require "safe/errors"
require "safe/job"
require "safe/worker"
require "safe/workflow"
require "safe/monitor_client"

require "safe/rails/models/safe/model"
require "safe/rails/models/safe/workflow_monitor"
require "safe/rails/models/safe/job_monitor"
require "safe/rails/models/safe/error_occurrence"

module SAFE
  def self.safefile
    configuration.safefile
  end

  def self.root
    Pathname.new(__FILE__).parent.parent
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end

if defined?(::Rails) && defined?(::Rails.application)
  require "safe/rails/engine"
else
  ::Kernel.warn("Rails not loaded")
end
