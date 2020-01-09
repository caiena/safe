module SAFE
  class JobMonitor < Model

    belongs_to :workflow_monitor

    has_many :error_occurrences, dependent: :delete_all

    validates :failures, :job, :job_id, :successes, :total, :workflow_monitor,
      presence: true

    validates :total, :successes, :failures,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def init(_job)
      self.job_id          = _job.id
      self.failures        = 0
      self.successes       = 0
      self.last_success_id = 0
      self.total           = _job.total_steps

      error_occurrences.clear
      save
    end

    def monitorable
      client.find_job(workflow_monitor.workflow_id, job)
    end

    def processed
      successes + failures
    end

    def status
      if monitorable.running?
        :running
      elsif monitorable.succeeded?
        :succeeded
      elsif monitorable.failed?
        :failed
      else
        :queued
      end
    end

    def track_failure
      track(:failures)
    end

    def track_record(obj)
      update!(last_success_id: obj.id)
    end

    def track_success
      track(:successes)
    end

    private

    def client
      @client ||= Client.new
    end

    def track(attr)
      increment(attr)
      save!
    end

  end
end
