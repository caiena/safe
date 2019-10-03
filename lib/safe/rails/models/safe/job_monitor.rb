module SAFE
  class JobMonitor < Model

    belongs_to :workflow_monitor

    has_many :error_occurrences, dependent: :destroy

    validates :failures, :job, :job_id, :successes, :total, :workflow_monitor,
      presence: true

    validates :total, :successes, :failures,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def processed
      successes + failures
    end

    def track_failure
      track(:failures)
    end

    def track_record(obj)
      update!(last_succcess_id: obj.id)
    end

    def track_success
      track(:successes)
    end

    private

    def track(attr)
      increment(attr)
      increment(:total)
      save!
    end

  end
end
