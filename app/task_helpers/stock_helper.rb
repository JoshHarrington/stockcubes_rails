## copy of app/helpers/stock_helper

module TaskStockHelper
	def user_stock_update(user_id, recipe_id, cupboard_stock_in_date_ingredient_ids, recipe_ingredient_ids)
		num_ingredients_total = recipe_ingredient_ids.length.to_i
		recipe_stock_ingredient_matches = recipe_ingredient_ids & cupboard_stock_in_date_ingredient_ids
		num_stock_ingredients = recipe_stock_ingredient_matches.length.to_i
		ingredient_stock_match_decimal = num_stock_ingredients.to_f / num_ingredients_total.to_f
		num_needed_ingredients = num_ingredients_total - num_stock_ingredients

		UserRecipeStockMatch.find_or_create_by(
			recipe_id: recipe_id,
			user_id: user_id
		).update_attributes(
			ingredient_stock_match_decimal: ingredient_stock_match_decimal,
			num_ingredients_total: num_ingredients_total,
			num_stock_ingredients: num_stock_ingredients,
			num_needed_ingredients: num_needed_ingredients
		)
	end

	def recipe_stock_matches_update(user_id = nil, recipe_id = nil)

		if user_id == nil && recipe_id != nil
			# updating all user stock matches for one recipe
			recipe = Recipe.find(recipe_id)
			recipe_ingredient_ids = recipe.ingredients.map(&:id)

			User.where(activated: true).each do |user|
				active_cupboard_ids = CupboardUser.where(user_id: user[:id], accepted: true).map{|cu| cu.cupboard.id unless cu.cupboard == nil && (cu.cupboard.setup == true || cu.cupboard.hidden == true) }.compact
				cupboard_stock_in_date_ingredient_ids = Stock.where(cupboard_id: active_cupboard_ids, hidden: false).where("use_by_date >= :date", date: Date.current - 2.days).uniq { |s| s.ingredient_id }.map{ |s| s.ingredient.id }.compact

				user_stock_update(user[:id], recipe_id, cupboard_stock_in_date_ingredient_ids, recipe_ingredient_ids)
			end
		elsif user_id != nil && (!recipe_id || recipe_id == nil)
			# updating all user stock matches for one user
			active_cupboard_ids = CupboardUser.where(user_id: user_id, accepted: true).map{|cu| cu.cupboard.id unless cu.cupboard == nil && (cu.cupboard.setup == true || cu.cupboard.hidden == true) }.compact
			cupboard_stock_in_date_ingredient_ids = Stock.where(cupboard_id: active_cupboard_ids, hidden: false).where("use_by_date >= :date", date: Date.current - 2.days).uniq { |s| s.ingredient_id }.map{ |s| s.ingredient.id }.compact

			Recipe.where(live: true, public: true).each do |recipe|
				user = User.find(user_id)
				recipe_ingredient_ids = recipe.ingredients.map(&:id)
				user_stock_update(user_id, recipe[:id], cupboard_stock_in_date_ingredient_ids, recipe_ingredient_ids)
			end
		end

	end
end