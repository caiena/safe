module SAFE
  class MonitorClient

    class << self

      def create(workflow, monitorable)
        monitor = create_workflow(workflow, monitorable)
        create_jobs(workflow.jobs, monitor)
      end

      def create_error(error:, job_monitor:, record: nil, params: nil)
        job_monitor.error_occurrences.create!(
          record:  record,
          params:  params,
          message: "#{error.class}: #{error.message}"
        )
      end

      def load_workflow(flow)
        WorkflowMonitor
          .where(workflow: flow.class.to_s, workflow_id: flow.id)
          .first
      end

      def load_job(job)
        JobMonitor
          .where(job: job.klass.to_s, job_id: job.id)
          .first
      end

      private

      def create_workflow(workflow, monitorable)
        WorkflowMonitor.where(
          workflow:    workflow.class.to_s,
          workflow_id: workflow.id,
          monitorable: monitorable
        ).first_or_create!
      end

      def create_jobs(jobs, monitor)
        jobs.each do |job|
          monitor.jobs.where(
            job:    job.class.to_s,
            job_id: job.id,
            total:  job.total_steps
          ).first_or_create!
        end
      end

    end

  end
end
