class AddProfessionToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :profession, :string
  end
end
