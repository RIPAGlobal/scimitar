class AddTimestampsToMockUser < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :mock_users
  end
end
