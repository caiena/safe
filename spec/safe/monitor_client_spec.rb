require 'spec_helper'

module SAFE
  RSpec.describe MonitorClient do

    let(:monitorable) { MonitorableMock.create! }

    let(:workflow_monitor) do
      WorkflowMonitor.create(
        workflow:    'TestWorkflow',
        workflow_id: '2346-5433',
        monitorable: monitorable
      )
    end

    # A suíte não limpa o banco entre exemplos: cada um usa um job_id próprio
    # para que a presença/ausência do JobMonitor seja de fato o que se testa.
    let(:job_id) { SecureRandom.uuid }
    let(:job)    { Prepare.new(id: job_id) }

    describe '.load_job' do
      it 'devolve o monitor do job e o inicializa' do
        JobMonitor.create!(
          workflow_monitor: workflow_monitor,
          job:              job.klass.to_s,
          job_id:           job.id,
          total:            0,
          successes:        0,
          failures:         0
        )

        expect(described_class.load_job(job)).to be_a(JobMonitor)
      end

      # Quando uma rodada NOVA do mesmo workflow é criada, `create_jobs` apaga
      # os JobMonitor da rodada anterior. Os workers da rodada antiga que ainda
      # estavam na fila caem aqui sem registro — antes isso levantava
      # "undefined method 'init' for nil" e derrubava o job.
      it 'devolve nil quando o monitor do job não existe' do
        expect { described_class.load_job(job) }.not_to raise_error
        expect(described_class.load_job(job)).to be_nil
      end
    end

    describe 'job sem monitor' do
      it 'conclui a execução sem estourar' do
        expect { job.finish_execution! }.not_to raise_error
      end

      it 'contabiliza sucesso e falha sem estourar' do
        expect { job.send(:increase_successes) }.not_to raise_error
        expect { job.send(:increase_failures) }.not_to raise_error
      end

      it 'não tenta registrar ocorrência de erro' do
        expect(described_class).not_to receive(:create_error)

        job.send(:create_error_occurrence, nil, StandardError.new('x'))
      end
    end
  end
end
