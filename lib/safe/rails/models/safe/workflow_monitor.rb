module SAFE
  class WorkflowMonitor < Model

    belongs_to :monitorable, polymorphic: true

    has_many :jobs, class_name: 'JobMonitor', dependent: :destroy

    validates :monitorable, presence: true
    validates :workflow,    presence: true
    validates :workflow_id, presence: true

  end
end
