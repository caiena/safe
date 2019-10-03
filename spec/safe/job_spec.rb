require 'spec_helper'

module SAFE
  RSpec.describe Job do

    describe "#output" do
      it "saves output to output_payload" do
        job = described_class.new(name: "a-job")
        job.output "something"
        expect(job.output_payload).to eq("something")
      end
    end
    describe "#fail!" do
      it "sets finished and failed to true and records time" do
        job = described_class.new(name: "a-job")
        job.fail!
        expect(job.failed_at).to eq(Time.now.to_i)
        expect(job.failed?).to eq(true)
        expect(job.finished?).to eq(true)
        expect(job.running?).to eq(false)
        expect(job.enqueued?).to eq(false)
      end
    end

    describe "#finish!" do
      it "sets finished to false and failed to false and records time" do
        job = described_class.new(name: "a-job")
        job.finish!
        expect(job.finished_at).to eq(Time.now.to_i)
        expect(job.failed?).to eq(false)
        expect(job.running?).to eq(false)
        expect(job.finished?).to eq(true)
        expect(job.enqueued?).to eq(false)
      end
    end

    describe "#enqueue!" do
      it "resets flags to false and sets enqueued to true" do
        job = described_class.new(name: "a-job")
        job.finished_at = 123
        job.failed_at = 123
        job.enqueue!
        expect(job.started_at).to eq(nil)
        expect(job.finished_at).to eq(nil)
        expect(job.failed_at).to eq(nil)
        expect(job.failed?).to eq(false)
        expect(job.finished?).to eq(false)
        expect(job.enqueued?).to eq(true)
        expect(job.running?).to eq(false)
      end
    end

    describe "#start!" do
      it "resets flags and marks as running" do
        job = described_class.new(name: "a-job")

        job.enqueue!
        job.fail!

        now = Time.now.to_i
        expect(job.started_at).to eq(nil)
        expect(job.failed_at).to eq(now)

        job.start!

        expect(job.started_at).to eq(Time.now.to_i)
        expect(job.failed_at).to eq(nil)
      end
    end

    describe '#track' do
      let(:obj_id)   { 10 }
      let(:workflow) { TestWorkflow.create(10) }
      let(:job)      { workflow.initial_jobs.first }
      let(:monitor)  { job.monitor }

      it 'has one job monitor' do
        expect(monitor).to be_kind_of(JobMonitor)
      end

      context 'success' do
        before { job.track { 'success' } }

        it 'increase success count' do
          expect(monitor.successes).to eq 1
        end

        it 'increase processed count' do
          expect(monitor.processed).to eq 1
        end

        context 'with trackable object' do
          let(:record) { MonitorableMock.create! }

          before { job.track(record) { 'success' } }

          it 'save record id' do
            expect(monitor.last_succcess_id).to eq record.id
          end
        end
      end

      context 'failure' do
        before { job.track { raise Exception } }

        it 'increase failure count' do
          expect(monitor.failures).to eq 1
        end

        it 'create a error occurrence' do
          expect { job.track { raise Exception } }.
            to change(ErrorOccurrence, :count).by(1)
        end

        context 'with trackable object' do
          let(:record)     { MonitorableMock.create! }
          let(:occurrence) { monitor.error_occurrences.last }

          before { job.track(record) { raise Exception, 'Some Message' } }

          it 'saves object to error occurrence' do
            expect(occurrence.record).to eq record
          end

          it 'save error message' do
            expect(occurrence.message).to eq "Exception: Some Message"
          end

          it 'save params' do
            expect(occurrence.params).to eq({ some_id: 10 })
          end
        end
      end
    end

    describe "#as_json" do
      context "finished and enqueued set to true" do
        it "returns correct hash" do
          job = described_class.new(workflow_id: 123, id: "702bced5-bb72-4bba-8f6f-15a3afa358bd", finished_at: 123, enqueued_at: 120)
          expected = {
            id: '702bced5-bb72-4bba-8f6f-15a3afa358bd',
            klass: "SAFE::Job",
            incoming: [],
            outgoing: [],
            failed_at: nil,
            started_at: nil,
            finished_at: 123,
            enqueued_at: 120,
            params: {},
            queue: nil,
            output_payload: nil,
            workflow_id: 123
          }
          expect(job.as_json).to eq(expected)
        end
      end
    end

    describe ".from_hash" do
      it "properly restores state of the job from hash" do
        job = described_class.from_hash(
          {
            klass: 'SAFE::Job',
            id: '702bced5-bb72-4bba-8f6f-15a3afa358bd',
            incoming: ['a', 'b'],
            outgoing: ['c'],
            failed_at: 123,
            finished_at: 122,
            started_at: 55,
            enqueued_at: 444
          }
        )

        expect(job.id).to eq('702bced5-bb72-4bba-8f6f-15a3afa358bd')
        expect(job.name).to eq('SAFE::Job|702bced5-bb72-4bba-8f6f-15a3afa358bd')
        expect(job.class).to eq(SAFE::Job)
        expect(job.klass).to eq("SAFE::Job")
        expect(job.finished?).to eq(true)
        expect(job.failed?).to eq(true)
        expect(job.enqueued?).to eq(true)
        expect(job.incoming).to eq(['a', 'b'])
        expect(job.outgoing).to eq(['c'])
        expect(job.failed_at).to eq(123)
        expect(job.finished_at).to eq(122)
        expect(job.started_at).to eq(55)
        expect(job.enqueued_at).to eq(444)
      end
    end
  end
end
