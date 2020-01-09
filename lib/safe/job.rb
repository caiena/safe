module SAFE
  class Job
    attr_accessor :workflow_id, :incoming, :outgoing, :params, :monitor,
      :finished_at, :failed_at, :started_at, :enqueued_at, :payloads, :klass, :queue
    attr_reader :id, :klass, :output_payload, :params

    def initialize(opts = {})
      options = opts.dup
      assign_variables(options)
    end

    def as_json
      {
        id: id,
        klass: klass.to_s,
        queue: queue,
        incoming: incoming,
        outgoing: outgoing,
        finished_at: finished_at,
        enqueued_at: enqueued_at,
        started_at: started_at,
        failed_at: failed_at,
        params: params,
        workflow_id: workflow_id,
        output_payload: output_payload
      }
    end

    def name
      @name ||= "#{klass}|#{id}"
    end

    def to_json(options = {})
      SAFE::JSON.encode(as_json)
    end

    def self.from_hash(hash)
      hash[:klass].constantize.new(hash)
    end

    def output(data)
      @output_payload = data
    end

    def perform
    end

    def total_steps
      0
    end

    def monitor
      @monitor ||= MonitorClient.load_job(self)
    end

    def start!
      @started_at = current_timestamp
      @failed_at = nil
    end

    def enqueue!
      @enqueued_at = current_timestamp
      @started_at = nil
      @finished_at = nil
      @failed_at = nil
    end

    def finish!
      @finished_at = current_timestamp
    end

    def fail!
      @finished_at = @failed_at = current_timestamp
    end

    def enqueued?
      !enqueued_at.nil?
    end

    def finished?
      !finished_at.nil?
    end

    def failed?
      !failed_at.nil?
    end

    def succeeded?
      finished? && !failed?
    end

    def started?
      !started_at.nil?
    end

    def running?
      started? && !finished?
    end

    def ready_to_start?
      !running? && !enqueued? && !finished? && !failed? && parents_succeeded?
    end

    def track(record=nil, &block)
      begin
        block.call
        increase_successes
        record_last_object(record)
      rescue *Array(recoverable_exceptions) => e
        increase_failures
        create_error_occurrence(record, e)
        record_last_object(record)
      end
    end

    def recoverable_exceptions
    end

    def order_and_track(collection, attr: :id)
      collection
        .where("#{collection.arel_table.name}.id > ?", last_recorded_id)
        .reorder(attr)
    end

    def last_recorded_id
      monitor&.last_success_id || 0
    end

    def parents_succeeded?
      !incoming.any? do |name|
        !client.find_job(workflow_id, name).succeeded?
      end
    end

    def has_no_dependencies?
      incoming.empty?
    end

    private

    def assign_variables(opts)
      @id             = opts[:id]
      @incoming       = opts[:incoming] || []
      @outgoing       = opts[:outgoing] || []
      @failed_at      = opts[:failed_at]
      @finished_at    = opts[:finished_at]
      @started_at     = opts[:started_at]
      @enqueued_at    = opts[:enqueued_at]
      @params         = opts[:params] || {}
      @klass          = opts[:klass] || self.class
      @output_payload = opts[:output_payload]
      @workflow_id    = opts[:workflow_id]
      @queue          = opts[:queue]
    end

    def create_error_occurrence(record, error)
      MonitorClient.create_error(
        record:      record,
        error:       error,
        params:      params,
        job_monitor: monitor
      )
    end

    def client
      @client ||= Client.new
    end

    def current_timestamp
      Time.now.to_i
    end

    def update_total_steps
      return unless monitor
      monitor.total = total_steps
      monitor.save
    end

    def record_last_object(object)
      return unless object.respond_to?(:id)
      monitor.track_record(object)
    end

    def increase_failures
      monitor.track_failure
    end

    def increase_successes
      monitor.track_success
    end

  end
end
