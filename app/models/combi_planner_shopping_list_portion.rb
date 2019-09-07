class CombiPlannerShoppingListPortion < ApplicationRecord
	self.table_name = "combi_planner_sl_portions"

	has_many 	 :planner_shopping_list_portions, dependent: :nullify

  belongs_to :user
  belongs_to :ingredient
	belongs_to :planner_shopping_list
	belongs_to :unit

  validates :amount, presence: true

end