class CreateJoinTableMockGroupsMockUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :mock_groups_users, id: false do | t |
      t.references :mock_group, foreign_key: true, type: :int8, index: true, null: false
      t.references :mock_user,                     type: :uuid, index: true, null: false, primary_key: :primary_key

      # The 'foreign_key:' option (used above) only works for 'id' column names
      # but the test data has a column named 'primary_key' for 'mock_users'.
      #
      t.foreign_key :mock_users, primary_key: :primary_key
    end
  end
end
