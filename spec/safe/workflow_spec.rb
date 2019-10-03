require 'spec_helper'

module SAFE
  describe Workflow do
    subject { TestWorkflow.create }

    describe '.find' do
      let(:flow) { TestWorkflow.create }

      let(:reloaded) { TestWorkflow.find(flow.id) }

      it 'link corresponding workflow monitor' do
        expect(reloaded.monitor).to be_kind_of(WorkflowMonitor)
      end

      it 'link job monitors to each job' do
        job = reloaded.jobs.first
        expect(job.monitor).to be_kind_of(JobMonitor)
      end
    end

    describe '.create_unique' do
      def start_workflow(flow)
        flow.start!
        flow.jobs.first.start!
        flow.save
      end

      context 'without linked_record' do
        let(:flow) { TestWorkflow.create_unique }

        before { start_workflow(flow) }

        let(:new_flow) { TestWorkflow.create_unique }

        it 'dont create a new flow if its running' do
          expect(new_flow.id).to eq flow.id
        end
      end

      context 'with linked_record' do
        let(:record) { MonitorableMock.create! }
        let(:flow) { TestWorkflow.create_unique(record) }

        before { start_workflow(flow) }

        context 'same linked_record' do
          let(:new_flow) { TestWorkflow.create_unique(record) }

          it 'dont create a new flow if its running' do
            expect(new_flow.id).to eq flow.id
          end
        end

        context 'different linked_record' do
          let(:record_b) { MonitorableMock.create! }
          let(:new_flow) { TestWorkflow.create_unique(record_b) }

          it 'create a new flow if its running' do
            expect(new_flow.id).not_to eq flow.id
          end
        end
      end
    end

    describe "#initialize" do
      it "passes constructor arguments to the method" do
        klass = Class.new(Workflow) do
          def configure(*args)
            run FetchFirstJob
            run PersistFirstJob, after: FetchFirstJob
          end
        end

        expect_any_instance_of(klass).to receive(:configure).with("arg1", "arg2")
        klass.new("arg1", "arg2")
      end
    end

    describe "#status" do
      context "when failed" do
        it "returns :failed" do
          flow = TestWorkflow.create
          flow.find_job("Prepare").fail!
          flow.persist!
          expect(flow.reload.status).to eq(:failed)
        end
      end
    end

    describe "#save" do
      context "workflow not persisted" do
        it "sets persisted to true" do
          flow = TestWorkflow.new
          flow.save
          expect(flow.persisted).to be(true)
        end

        it "assigns new unique id" do
          flow = TestWorkflow.new
          flow.save
          expect(flow.id).to_not be_nil
        end

        context 'active record persistence' do
          it 'create a WorkflowMonitor record' do
            expect{ TestWorkflow.create }.to change(WorkflowMonitor, :count).by(1)
          end

          it 'create a JobMonitor record for each job' do
            expect{ TestWorkflow.create }.to change(JobMonitor, :count).by(5)
          end

          it 'track monitorable record' do
            record = MonitorableMock.create!
            flow = TestWorkflow.new
            flow.link(record)
            flow.save
            expect(WorkflowMonitor.last.monitorable).to eq record
          end
        end
      end

      context "workflow persisted" do
        it "does not assign new id" do
          flow = TestWorkflow.new
          flow.save
          id = flow.id
          flow.save
          expect(flow.id).to eq(id)
        end

        context 'active record peristence' do
          let(:flow) { TestWorkflow.new }

          before { flow.save }

          it 'does not create a workflow monitor record' do
            expect{ flow.save }.not_to change(WorkflowMonitor, :count)
          end

          it 'does not create a job monitor records' do
            expect{ flow.save }.not_to change(JobMonitor, :count)
          end
        end
      end
    end

    describe "#continue" do
      it "enqueues failed jobs" do
        flow = TestWorkflow.create
        flow.find_job('Prepare').fail!

        expect(flow.jobs.select(&:failed?)).not_to be_empty

        flow.continue

        expect(flow.jobs.select(&:failed?)).to be_empty
        expect(flow.find_job('Prepare').failed_at).to be_nil
      end
    end

    describe "#mark_as_stopped" do
      it "marks workflow as stopped" do
        expect{ subject.mark_as_stopped }.to change{subject.stopped?}.from(false).to(true)
      end
    end

    describe "#mark_as_started" do
      it "removes stopped flag" do
        subject.stopped = true
        expect{ subject.mark_as_started }.to change{subject.stopped?}.from(true).to(false)
      end
    end

    describe "#to_json" do
      it "returns correct hash" do
        klass = Class.new(Workflow) do
          def configure(*args)
            run FetchFirstJob
            run PersistFirstJob, after: FetchFirstJob
          end
        end

        result = ::JSON.parse(klass.create("arg1", "arg2").to_json)
        expected = {
          "id" => an_instance_of(String),
          "name" => klass.to_s,
          "klass" => klass.to_s,
          "status" => "running",
          "total" => 2,
          "finished" => 0,
          "started_at" => nil,
          "finished_at" => nil,
          "stopped" => false,
          "arguments" => ["arg1", "arg2"]
        }
        expect(result).to match(expected)
      end
    end

    describe "#find_job" do
      it "finds job by its name" do
        expect(TestWorkflow.create.find_job("PersistFirstJob")).to be_instance_of(PersistFirstJob)
      end
    end

    describe '#link' do
      let(:flow) {  Workflow.new }

      subject { flow.instance_variable_get(:"@linked_record") }

      context 'without object' do
        it { is_expected.to be_nil }
      end

      context 'with object' do
        before { flow.link('foo') }

        it { is_expected.to eq 'foo' }
      end
    end

    describe "#run" do
      it "allows passing additional params to the job" do
        flow = Workflow.new
        flow.run(Job, params: { something: 1 })
        flow.save
        expect(flow.jobs.first.params).to eq ({ something: 1 })
      end

      context "when graph is empty" do
        it "adds new job with the given class as a node" do
          flow = Workflow.new
          flow.run(Job)
          flow.save
          expect(flow.jobs.first).to be_instance_of(Job)
        end
      end

      it "allows `after` to accept an array of jobs" do
        tree = Workflow.new
        klass1 = Class.new(Job)
        klass2 = Class.new(Job)
        klass3 = Class.new(Job)

        tree.run(klass1)
        tree.run(klass2, after: [klass1, klass3])
        tree.run(klass3)

        tree.resolve_dependencies

        expect(tree.jobs.first.outgoing).to match_array(jobs_with_id([klass2.to_s]))
      end

      it "allows `before` to accept an array of jobs" do
        tree = Workflow.new
        klass1 = Class.new(Job)
        klass2 = Class.new(Job)
        klass3 = Class.new(Job)
        tree.run(klass1)
        tree.run(klass2, before: [klass1, klass3])
        tree.run(klass3)

        tree.resolve_dependencies

        expect(tree.jobs.first.incoming).to match_array(jobs_with_id([klass2.to_s]))
      end

      it "attaches job as a child of the job in `after` key" do
        tree = Workflow.new
        klass1 = Class.new(Job)
        klass2 = Class.new(Job)
        tree.run(klass1)
        tree.run(klass2, after: klass1)
        tree.resolve_dependencies
        job = tree.jobs.first
        expect(job.outgoing).to match_array(jobs_with_id([klass2.to_s]))
      end

      it "attaches job as a parent of the job in `before` key" do
        tree = Workflow.new
        klass1 = Class.new(Job)
        klass2 = Class.new(Job)
        tree.run(klass1)
        tree.run(klass2, before: klass1)
        tree.resolve_dependencies
        job = tree.jobs.first
        expect(job.incoming).to match_array(jobs_with_id([klass2.to_s]))
      end
    end

    describe "#failed?" do
      context "when one of the jobs failed" do
        it "returns true" do
          subject.find_job('Prepare').fail!
          expect(subject.failed?).to be_truthy
        end
      end

      context "when no jobs failed" do
        it "returns true" do
          expect(subject.failed?).to be_falsy
        end
      end
    end

    describe "#running?" do
      context "when no enqueued or running jobs" do
        it "returns false" do
          expect(subject.running?).to be_falsy
        end
      end

      context "when some jobs are running" do
        it "returns true" do
          subject.find_job('Prepare').start!
          expect(subject.running?).to be_truthy
        end
      end
    end

    describe "#finished?" do
      it "returns false if any jobs are unfinished" do
        expect(subject.finished?).to be_falsy
      end

      it "returns true if all jobs are finished" do
        subject.jobs.each {|n| n.finish! }
        expect(subject.finished?).to be_truthy
      end
    end
  end
end
