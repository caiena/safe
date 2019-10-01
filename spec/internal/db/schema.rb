# frozen_string_literal: true

ActiveRecord::Schema.define do

  create_table(:safe_workflow_monitors, force: true) do |t|
    t.string   :workflow,    null: false
    t.string   :workflow_id, null: false
    t.bigint   :monitorable_type
    t.string   :monitorable_id

    t.timestamps
  end

  create_table(:safe_job_monitors, force: true) do |t|
    t.bigint   :workflow_monitor_id, foreign_key: true, null: false, index: true
    t.string   :job,       null: false
    t.string   :job_id,    null: false
    t.integer  :total,     null: false, default: 0
    t.integer  :successes, null: false, default: 0
    t.integer  :failures,  null: false, default: 0

    t.timestamps
  end

  create_table(:safe_error_occurrences, force: true) do |t|
    t.bigint   :job_monitor_id, foreign_key: true, null: false, index: true
    t.bigint   :record_type
    t.string   :record_id
    t.string   :params
    t.text     :message

    t.timestamps
  end

  create_table(:monitorable_mocks, force: true) do |t|
    t.timestamps
  end

end
