class CreateFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flags do |t|
      t.string :name, null: false
      t.boolean :global_default_state, null: false, default: false
      t.text :description

      t.timestamps
    end
    add_index :feature_flags, :name, unique: true
  end
end
