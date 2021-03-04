class CreateMockUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :mock_users do |t|

      t.text :scim_uid
      t.text :username
      t.text :first_name
      t.text :last_name
      t.text :work_email_address
      t.text :work_phone_number

    end
  end
end
