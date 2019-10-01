require 'spec_helper'

module SAFE
  RSpec.describe WorkflowMonitor do

    WorkflowMock = Struct.new(:id)

    describe 'associations' do
      it 'belongs_to monitorable' do
        association = described_class.reflect_on_association(:monitorable)
        expect(association.macro).to eq :belongs_to
      end

      it 'have_many jobs' do
        association = described_class.reflect_on_association(:jobs)
        expect(association.macro).to eq :has_many
      end
    end

    describe 'validations' do
      let(:workflow) { WorkflowMock.new('2345-3432-3242') }
      let(:monitorable) { MonitorableMock.create! }

      let(:monitor) do
        described_class.new(
          workflow:    workflow.class,
          workflow_id: workflow.id,
          monitorable: monitorable
        )
      end

      it 'is valid with valid attributes' do
        expect(monitor.valid?).to be_truthy
      end

      it 'is invalid without workflow' do
        monitor.workflow = nil
        expect(monitor.valid?).to be_falsey
      end

      it 'is invalid without workflow_id' do
        monitor.workflow_id = nil
        expect(monitor.valid?).to be_falsey
      end

      it 'is invalid without monitorable' do
        monitor.monitorable = nil
        expect(monitor.valid?).to be_falsey
      end
    end

  end
end
