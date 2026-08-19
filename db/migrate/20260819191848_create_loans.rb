class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.date :borrowed_on, null: false
      t.date :due_on, null: false
      # Nul tant que le livre n'est pas revenu : c'est ce qui distingue un
      # prêt en cours d'un prêt terminé.
      t.date :returned_on
      t.integer :renewals_count, null: false, default: 0

      t.timestamps
    end

    # Vérifier qu'un abonné n'a pas déjà un livre : requête faite à chaque prêt.
    add_index :loans, [ :member_id, :returned_on ]
    # Compter les exemplaires sortis d'un ouvrage, pour la disponibilité.
    add_index :loans, [ :book_id, :returned_on ]
    # Liste des retards, triée par ancienneté.
    add_index :loans, :due_on
  end
end
