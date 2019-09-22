class Ingredient < ApplicationRecord
	belongs_to :unit, optional: true
	has_many :portions, dependent: :delete_all
	has_many :recipes, through: :portions
	has_many :stocks, dependent: :delete_all
	has_many :cupboards, through: :stocks
	has_many :planner_shopping_list_portions, dependent: :delete_all
	has_many :combi_planner_shopping_list_portions, dependent: :delete_all
	has_one :user_fav_stock, dependent: :delete

	searchkick

  def search_data
    {name: name}
  end

end
