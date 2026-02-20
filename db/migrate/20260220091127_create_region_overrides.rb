class CreateRegionOverrides < ActiveRecord::Migration[8.0]
  def change
    create_table :region_overrides do |t|
      t.references :feature_flag, null: false, foreign_key: true
      t.string :region, null: false
      t.boolean :enabled, null: false

      t.timestamps
    end
    add_index :region_overrides, [:feature_flag_id, :region], unique: true
  end
end
