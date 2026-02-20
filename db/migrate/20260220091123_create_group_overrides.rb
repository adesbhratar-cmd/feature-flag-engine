class CreateGroupOverrides < ActiveRecord::Migration[8.0]
  def change
    create_table :group_overrides do |t|
      t.references :feature_flag, null: false, foreign_key: true
      t.string :group_id, null: false
      t.boolean :enabled, null: false

      t.timestamps
    end
    add_index :group_overrides, [:feature_flag_id, :group_id], unique: true
  end
end
