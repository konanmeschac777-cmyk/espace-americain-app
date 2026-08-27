class AddDetailsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :age, :integer
    add_column :members, :neighborhood, :string
    add_column :members, :suspended_until, :date
  end
end
