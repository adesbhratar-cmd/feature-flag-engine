class CreateUserOverrides < ActiveRecord::Migration[8.0]
  def change
    create_table :user_overrides do |t|
      t.references :feature_flag, null: false, foreign_key: true
      t.string :user_id, null: false
      t.boolean :enabled, null: false

      t.timestamps
    end
    add_index :user_overrides, [:feature_flag_id, :user_id], unique: true
  end
end
