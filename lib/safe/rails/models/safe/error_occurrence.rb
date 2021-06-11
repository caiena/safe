module SAFE
  class ErrorOccurrence < Model
    serialize :params

    belongs_to :job_monitor, counter_cache: true
    belongs_to :record, polymorphic: true

    validates :message, :job_monitor, presence: true

  end
end
