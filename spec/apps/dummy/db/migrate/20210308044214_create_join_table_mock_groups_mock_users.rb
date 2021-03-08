class CreateJoinTableMockGroupsMockUsers < ActiveRecord::Migration[6.1]
  def change
    create_join_table :mock_groups, :mock_users do |t|
      t.index [:mock_group_id, :mock_user_id]
      t.index [:mock_user_id, :mock_group_id]
    end
  end
end
