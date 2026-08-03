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
          message: "#{error.class}: #{error.message}"
        )
      end

      def load_workflow(flow, monitorable)
        WorkflowMonitor
          .where(workflow: flow.class.to_s, monitorable: monitorable, workflow_id: flow.id)
          .first
      end

      # O monitor do job pode NÃO existir: quando um novo workflow é criado
      # para o mesmo recurso, `create_jobs` apaga os JobMonitor da rodada
      # anterior (`monitor.jobs.delete_all`). Os workers da rodada antiga que
      # ainda estavam na fila passam então a procurar um registro já removido.
      #
      # Nesse caso devolvemos nil em vez de estourar NoMethodError: a rodada
      # antiga foi superada e não tem mais o que acompanhar. Antes, o
      # `.first.tap` levantava "undefined method 'init' for nil" dentro do
      # worker, derrubando o job e deixando o workflow travado.
      def load_job(job)
        JobMonitor
          .where(job: job.klass.to_s, job_id: job.id)
          .first
          &.tap { |job_monitor| job_monitor.init(job) }
      end

      private

      def create_workflow(workflow, monitorable)
        monitor = WorkflowMonitor.where(
          workflow: workflow.class.to_s,
          monitorable_id: monitorable.try(:id),
          monitorable_type: monitorable.try(:class).try(:to_s)
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
