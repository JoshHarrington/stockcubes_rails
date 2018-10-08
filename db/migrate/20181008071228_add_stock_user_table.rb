class AddStockUserTable < ActiveRecord::Migration[5.1]
  def change
    create_table :stock_users do |t|
      t.belongs_to :stock, index: true
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end