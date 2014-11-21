ActiveRecord::Schema.define(version: 0) do
  create_table(:test_subjects, force: true) do |t|
    t.string :targeted_id, null: false
    t.string :name, null: false
    t.string :email, null: false
  end
end
