require 'spec_helper'

module SAFE
  RSpec.describe ErrorOccurrence do

    describe 'associations' do
      it 'belongs_to job_monitor' do
        association = described_class.reflect_on_association(:job_monitor)
        expect(association.macro).to eq :belongs_to
      end

      it 'belongs_to record' do
        association = described_class.reflect_on_association(:record)
        expect(association.macro).to eq :belongs_to
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

      let!(:job_monitor) do
        JobMonitor.create(
          workflow_monitor: workflow_monitor,
          job: 'SomeJob',
          job_id: '3433-4535'
        )
      end

      let(:error_occurrence) do
        described_class.new(
          job_monitor: job_monitor,
          record: MonitorableMock.create!,
          message: 'Some error message'
        )
      end

      it 'is valid with valid attributes' do
        expect(error_occurrence.valid?).to be_truthy
      end

      it 'is invalid without workflow monitor' do
        error_occurrence.job_monitor = nil
        expect(error_occurrence.valid?).to be_falsey
      end

      it 'is invalid without message' do
        error_occurrence.message = nil
        expect(error_occurrence.valid?).to be_falsey
      end

    end
  end
end
