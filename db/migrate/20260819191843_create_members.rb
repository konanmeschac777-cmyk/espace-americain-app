class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.references :site, null: false, foreign_key: true
      t.string :card_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.date :joined_on, null: false
      # L'abonnement dure un an. Les états "actif", "expire bientôt" et
      # "expiré" se déduisent de cette date, ils ne sont pas stockés.
      t.date :expires_on, null: false
      # La suspension, elle, est une décision du bibliothécaire.
      t.boolean :suspended, null: false, default: false
      t.text :notes

      t.timestamps
    end
    add_index :members, :card_number, unique: true
    add_index :members, :last_name
    # Sert l'écran des renouvellements, consulté en début de mois.
    add_index :members, :expires_on
  end
end
