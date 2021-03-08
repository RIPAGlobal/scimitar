class CreateMockGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :mock_groups do |t|
      t.text :scim_uid
      t.text :display_name

      t.references :parent
    end
  end
end
