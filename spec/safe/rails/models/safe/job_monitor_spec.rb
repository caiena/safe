require 'spec_helper'

module SAFE
  RSpec.describe JobMonitor do

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
  end
end
