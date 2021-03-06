require 'securerandom'

module SAFE
  class Workflow
    attr_accessor :id, :jobs, :stopped, :persisted, :arguments, :monitor, :linked_type, :linked_id
    attr_reader :linked_record

    def initialize(*args)
      @id = id
      @jobs = []
      @dependencies = []
      @persisted = false
      @stopped = false
      @arguments = args

      setup
    end

    class << self
      # Create a instance of Workflow with given arguments
      #
      # @param args [Any]
      #
      # @return [SAFE::Workflow]
      #
      def create(*args)
        flow = new(*args)
        flow.save
        flow
      end

      # Load or create an workflow. If any workflow
      # of same class exists and is running, returns it.
      # Otherwise create a new one.
      #
      # If workflow has an linked_record it will use it to
      # scope the existing record, if not will only consider
      # workflow class and status
      #
      # @param args [Any]
      #
      # @return [SAFE::Workflow]
      #
      def create_unique(*args)
        workflow = find_running(new(*args))
        workflow || create(*args)
      end

      # Load an workflow based on its unique id
      #
      # @param id [String]
      #
      # @return [SAFE::Workflow]
      #
      def find(id)
        client.find_workflow(id)
      end

      private

      def client
        Client.new
      end

      def find_running(new_flow)
        params = { klass: new_flow.class.to_s }

        params.merge!({
          linked_type: new_flow.linked_record.class.to_s,
          linked_id:   new_flow.linked_record.id.to_i
        }) if new_flow.linked_record

        client.find_not_finished_workflow_by(params)
      end
    end

    def continue
      client = SAFE::Client.new
      failed_jobs = jobs.select(&:failed?)

      failed_jobs.each do |job|
        client.enqueue_job(id, job)
      end
    end

    def save
      persist!
    end

    def configure(*args)
    end

    def mark_as_stopped
      @stopped = true
    end

    def start!
      client.start_workflow(self)
    end

    def persist!
      client.persist_workflow(self).tap { |persisted| set_monitor if persisted }
    end

    def expire! (ttl=nil)
      client.expire_workflow(self, ttl)
    end

    def mark_as_persisted
      @persisted = true
    end

    def mark_as_started
      @stopped = false
    end

    def resolve_dependencies
      @dependencies.each do |dependency|
        from = find_job(dependency[:from])
        to   = find_job(dependency[:to])

        to.incoming << dependency[:from]
        from.outgoing << dependency[:to]
      end
    end

    def find_job(name)
      match_data = /(?<klass>\w*[^-])-(?<identifier>.*)/.match(name.to_s)

      if match_data.nil?
        job = jobs.find { |node| node.klass.to_s == name.to_s }
      else
        job = jobs.find { |node| node.name.to_s == name.to_s }
      end

      job
    end

    def finished?
      jobs.all?(&:finished?)
    end

    def started?
      !!started_at
    end

    def running?
      started? && !finished?
    end

    def failed?
      jobs.any?(&:failed?)
    end

    def stopped?
      stopped
    end

    def run(klass, opts = {})
      node = klass.new({
        workflow_id: id,
        id: client.next_free_job_id(id, klass.to_s),
        params: opts.fetch(:params, {}),
        queue: opts[:queue]
      })

      jobs << node

      deps_after = [*opts[:after]]

      deps_after.each do |dep|
        @dependencies << {from: dep.to_s, to: node.name.to_s }
      end

      deps_before = [*opts[:before]]

      deps_before.each do |dep|
        @dependencies << {from: node.name.to_s, to: dep.to_s }
      end

      node.name
    end

    def link(obj)
      @linked_record = obj
    end

    def reload
      flow = self.class.find(id)

      self.jobs = flow.jobs
      self.stopped = flow.stopped

      self
    end

    def initial_jobs
      jobs.select(&:has_no_dependencies?)
    end

    def status
      case
      when failed?
        :failed
      when running?
        :running
      when finished?
        :finished
      when stopped?
        :stopped
      else
        :running
      end
    end

    def started_at
      first_job ? first_job.started_at : nil
    end

    def finished_at
      last_job ? last_job.finished_at : nil
    end

    def to_hash
      name = self.class.to_s
      {
        name: name,
        id: id,
        arguments: @arguments,
        total: jobs.count,
        finished: jobs.count(&:finished?),
        klass: name,
        status: status,
        stopped: stopped,
        started_at: started_at,
        finished_at: finished_at
      }.merge!(linked_obj_attrs)
    end

    def linked_obj_attrs
      return {} unless linked_record && linked_record.respond_to?(:id)
      {
        linked_type: linked_record.class.to_s,
        linked_id:   linked_record.id
      }
    end

    def to_json(options = {})
      SAFE::JSON.encode(to_hash)
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def id
      @id ||= client.next_free_workflow_id
    end

    private

    def setup
      configure(*@arguments)
      resolve_dependencies
    end

    def client
      @client ||= Client.new
    end

    def first_job
      jobs.min_by{ |n| n.started_at || Time.now.to_i }
    end

    def last_job
      jobs.max_by{ |n| n.finished_at || 0 } if finished?
    end

    def set_monitor
      self.monitor = MonitorClient.create(self, linked_record)
    end
  end
end
