class AddPhoneCountryCodeToMembers < ActiveRecord::Migration[8.1]
  def change
    # La quasi-totalité des abonnés sont en Côte d'Ivoire : +225 par défaut,
    # changeable au cas par cas pour un visiteur étranger.
    add_column :members, :phone_country_code, :string, default: "+225", null: false
  end
end
