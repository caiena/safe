module SAFE
  class WorkflowMonitor < Model

    belongs_to :monitorable, polymorphic: true

    has_many :jobs, class_name: 'JobMonitor', dependent: :destroy

    validates :workflow,    presence: true
    validates :workflow_id, presence: true

    class << self

      def for_linked_resource(resource)
        where(monitorable: resource).order(created_at: :desc)
      end
    end

    def workflow_status
      workflow_klass.find(workflow_id).status
    end

    private

    def workflow_klass
      workflow.constantize
    end

  end
end
