class CreateMockUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :mock_users, id: :uuid, primary_key: :primary_key do |t|
      t.timestamps

      # Support part of the core schema
      #
      t.text :scim_uid
      t.text :username
      t.text :password
      t.text :first_name
      t.text :last_name
      t.text :work_email_address
      t.text :home_email_address
      t.text :work_phone_number

      # Support the custom extension schema - see configuration in
      # "spec/apps/dummy/config/initializers/scimitar.rb".
      #
      t.text :organization
      t.text :department
    end
  end
end
