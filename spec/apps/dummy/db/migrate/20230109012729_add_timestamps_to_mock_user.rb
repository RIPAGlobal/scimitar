class AddTimestampsToMockUser < ActiveRecord::Migration[6.1]
  def change
    add_timestamps :mock_users
  end
end
