require "bundler/setup"

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
