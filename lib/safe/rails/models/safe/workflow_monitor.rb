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

      def last_for_resource_and_flow(resource, workflow)
        for_linked_resource(resource).where(workflow: workflow).limit(1).first
      end
    end

    def workflow_status
      workflow_klass.find(workflow_id).status
    end

    def init(flow_id)
      self.workflow_id = flow_id
      save
    end

    private

    def workflow_klass
      workflow.constantize
    end

  end
end
