class ChangeEmailAndEncryptedPasswordOnUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :email, ""
    change_column_null :users, :email, false
    change_column_default :users, :encrypted_password, ""
    change_column_null :users, :encrypted_password, false
  end
end
