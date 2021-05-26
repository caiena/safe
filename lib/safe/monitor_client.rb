module SAFE
  class MonitorClient
    class << self
      def create(workflow, monitorable)
        monitor = create_workflow(workflow, monitorable)
        create_jobs(workflow.jobs, monitor)
        monitor
      end

      def create_error(error:, job_monitor:, record: nil, params: nil)
        job_monitor.error_occurrences.create!(
          record: record,
          params: params,
          message: "#{error.class}: #{error.message}"
        )
      end

      def load_workflow(flow, monitorable)
        WorkflowMonitor
          .where(workflow: flow.class.to_s, monitorable: monitorable, workflow_id: flow.id)
          .first
      end

      def load_job(job)
        JobMonitor
          .where(job: job.klass.to_s, job_id: job.id)
          .first
      end

      private

      def create_workflow(workflow, monitorable)
        monitor = WorkflowMonitor.where(
          workflow: workflow.class.to_s,
          monitorable: monitorable
        ).first_or_initialize

        monitor.init(workflow.id)
        monitor
      end

      def create_jobs(jobs, monitor)
        monitor.jobs.delete_all

        jobs.each do |job|
          job_monitor = monitor.jobs.where(job: job.class.to_s, job_id: job.id).first_or_initialize
          job_monitor.init(job)
        end
      end
    end
  end
end
