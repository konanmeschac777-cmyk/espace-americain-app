class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.references :site, null: false, foreign_key: true
      t.string :title, null: false
      # L'auteur reste facultatif : le fichier source du fonds ne le contenait
      # pas. Une fiche sans auteur est un travail en attente, pas une erreur.
      t.string :author
      t.boolean :author_confirmed, null: false, default: false
      t.references :category, null: false, foreign_key: true
      t.string :language, null: false, default: "fr"
      t.string :collection
      t.date :received_on
      t.integer :total_copies, null: false, default: 1
      t.string :shelf_mark
      t.text :summary
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Un même titre ne peut pas être saisi deux fois sur le même site.
    add_index :books, [ :site_id, :title ], unique: true
  end
end
