require 'spec_helper'

module SAFE
  RSpec.describe JobMonitor do

    let(:workflow_monitor) do
      WorkflowMonitor.create(
        workflow:    'WorkflowClass',
        workflow_id: '2346-5433',
        monitorable: MonitorableMock.create!
      )
    end

    let(:job_monitor) do
      described_class.new(
        workflow_monitor: workflow_monitor,
        job: 'SomeJob',
        job_id: '3433-4535'
      )
    end

    describe 'associations' do
      it 'belongs_to workflow_monitor' do
        association = described_class.reflect_on_association(:workflow_monitor)
        expect(association.macro).to eq :belongs_to
      end

      it 'has_many error_occurrences' do
        association = described_class.reflect_on_association(:error_occurrences)
        expect(association.macro).to eq :has_many
      end
    end

    describe 'validations' do
      it 'is valid with valid attributes' do
        expect(job_monitor.valid?).to be_truthy
      end

      it 'is invalid without workflow monitor' do
        job_monitor.workflow_monitor = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid without job' do
        job_monitor.job = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid without job_id' do
        job_monitor.job_id = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid without total' do
        job_monitor.total = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid without successes' do
        job_monitor.successes = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid without failures' do
        job_monitor.failures = nil
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid with non numeric total' do
        job_monitor.total = 'foo'
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid with non numeric successes' do
        job_monitor.successes = 'aa'
        expect(job_monitor.valid?).to be_falsey
      end

      it 'is invalid with non numeric failures' do
        job_monitor.failures = '143d'
        expect(job_monitor.valid?).to be_falsey
      end
    end

    describe '#processed' do
      before do
        job_monitor.track_success
        job_monitor.track_success
        job_monitor.track_failure
      end

      it 'sum successes and failures' do
        expect(job_monitor.processed).to eq 3
      end
    end

    describe '#status' do
      subject { job_monitor.status }

      context 'without monitorable' do
        it { is_expected.to eq :unknown }
      end

      context 'monitorable is running' do
        before do
          monitorable = spy 'job', running?: true
          allow(job_monitor).to receive(:monitorable).and_return(monitorable)
        end

        it { is_expected.to eq :running }
      end

      context 'monitorable is succeeded' do
        before do
          monitorable = spy 'job', running?: false, succeeded?: true
          allow(job_monitor).to receive(:monitorable).and_return(monitorable)
        end

        it { is_expected.to eq :succeeded }
      end

      context 'monitorable is failed' do
        before do
          monitorable = spy 'job', running?: false, succeeded?: false, failed?: true
          allow(job_monitor).to receive(:monitorable).and_return(monitorable)
        end

        it { is_expected.to eq :failed }
      end

      context 'monitorable is queued' do
        before do
          monitorable = spy 'job', running?: false, succeeded?: false, failed?: false
          allow(job_monitor).to receive(:monitorable).and_return(monitorable)
        end

        it { is_expected.to eq :queued }
      end
    end

    describe '#track_success' do
      it 'increment successes' do
        expect(job_monitor.successes).to eq 0
        job_monitor.track_success
        expect(job_monitor.successes).to eq 1
      end

      it 'increment processed' do
        expect(job_monitor.processed).to eq 0
        job_monitor.track_success
        expect(job_monitor.processed).to eq 1
      end

      it 'persist to db' do
        job_monitor.track_success
        expect(job_monitor.persisted?).to be_truthy
      end
    end

    describe '#track_failure' do
      it 'increment successes' do
        expect(job_monitor.failures).to eq 0
        job_monitor.track_failure
        expect(job_monitor.failures).to eq 1
      end

      it 'increment processed' do
        expect(job_monitor.processed).to eq 0
        job_monitor.track_failure
        expect(job_monitor.processed).to eq 1
      end

      it 'persist to db' do
        job_monitor.track_failure
        expect(job_monitor.persisted?).to be_truthy
      end
    end

  end
end
