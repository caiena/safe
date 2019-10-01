module SAFE
  class JobMonitor < Model

    belongs_to :workflow_monitor

    has_many :error_occurrences, dependent: :destroy

    validates :failures, :job, :job_id, :successes, :total, :workflow_monitor,
      presence: true

    validates :total, :successes, :failures,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  end
end
