class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :code, null: false
      t.string :name, null: false
      # Seul Tiassalé est actif au MVP. Les autres antennes existent en base
      # pour que leur ouverture ne demande pas de migration.
      t.boolean :active, null: false, default: false

      t.timestamps
    end
    add_index :sites, :code, unique: true
  end
end
