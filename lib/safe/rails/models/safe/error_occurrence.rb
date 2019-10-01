module SAFE
  class ErrorOccurrence < Model

    belongs_to :job_monitor
    belongs_to :record, polymorphic: true

    validates :message, :job_monitor, presence: true

  end
end
