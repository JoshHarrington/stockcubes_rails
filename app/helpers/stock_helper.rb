module StockHelper
	# if updating one or more ingredients (stock addition) - ingredient_id should be defined
	# if no ingredient_id defined then use all of current users stock to search for matching recipes


	def update_recipe_stock_matches_core(ingredient_ids = nil, user_id = nil, recipe_ids = nil)

		if user_id != nil
			user_id = user_id
		elsif current_user
			user_id = current_user[:id]
		else
			return
		end

		active_cupboard_ids = CupboardUser.where(user_id: user_id, accepted: true).map{|cu| cu.cupboard.id unless cu.cupboard == nil && (cu.cupboard.setup == true || cu.cupboard.hidden == true) }.compact
		cupboard_stock_in_date_ingredient_ids = Stock.where(cupboard_id: active_cupboard_ids, hidden: false, planner_recipe_id: nil).where("use_by_date >= :date", date: Date.current - 2.days).map{ |s| s.ingredient_id }.uniq.compact

		filtered_ingredient_ids = [].push(ingredient_ids).uniq.flatten.compact
		filtered_recipe_ids = [].push(recipe_ids).uniq.flatten.compact

		search_recipes = []
		collected_recipes = []
		if filtered_recipe_ids.length > 0
			collected_recipes = Recipe.find(filtered_recipe_ids)
		elsif filtered_ingredient_ids.length > 0
			ingredient_names = Ingredient.find(filtered_ingredient_ids).map(&:name)
			search_recipes = Recipe.search(ingredient_names, operator: "or", fields: ["ingredient_names^100"]).results.uniq
		end
		if filtered_recipe_ids.length == 0 && filtered_ingredient_ids.length == 0
			collected_recipes = Recipe.all.uniq.reject{|r| !r.portions || r.portions.length == 0}
		end

		all_recipes = collected_recipes + search_recipes
		all_recipes.each do |recipe|
			recipe_stock_update(recipe, cupboard_stock_in_date_ingredient_ids, user_id)
		end
	end

	def	update_recipe_stock_matches(ingredient_ids = nil, user_id = nil, recipe_ids = nil)
		return unless current_user.user_recipe_stock_matches.order("updated_at desc").first.updated_at < 20.minutes.ago
		update_recipe_stock_matches_core(ingredient_ids, user_id, recipe_ids)

		flash[:info] = %Q[We've updated your <a href="/recipes">recipe list</a> based on your stock so you can see the quickest recipes to make]

	end

	def recipe_stock_update(recipe, cupboard_stock_in_date_ingredient_ids, user_id)
		recipe_ingredient_ids = recipe.portions.map(&:ingredient_id)
		num_ingredients_total = recipe_ingredient_ids.length.to_i
		recipe_stock_ingredient_matches = recipe_ingredient_ids & cupboard_stock_in_date_ingredient_ids
		num_stock_ingredients = recipe_stock_ingredient_matches.length.to_i
		ingredient_stock_match_decimal = num_stock_ingredients.to_f / num_ingredients_total.to_f
		num_needed_ingredients = num_ingredients_total - num_stock_ingredients

		UserRecipeStockMatch.find_or_create_by(
			recipe_id: recipe[:id],
			user_id: user_id
		).update_attributes(
			ingredient_stock_match_decimal: ingredient_stock_match_decimal,
			num_ingredients_total: num_ingredients_total,
			num_stock_ingredients: num_stock_ingredients,
			num_needed_ingredients: num_needed_ingredients
		)
	end

	def toggle_stock_on_portion_check(portion, processing_type)

		return unless params.has_key?(:shopping_list_portion_id) && current_user && params.has_key?(:portion_type)
		current_user.planner_shopping_lists.first.update_attributes(
			ready: false
		)
		planner_portion_id_hash = Hashids.new(ENV['PLANNER_PORTIONS_SALT'])
		if params[:portion_type] == 'combi_portion'
			combi_portion = current_user.combi_planner_shopping_list_portions.find(planner_portion_id_hash.decode(params[:shopping_list_portion_id])).first
		elsif params[:portion_type] == 'individual_portion'
			individual_portion = current_user.planner_shopping_list_portions.find(planner_portion_id_hash.decode(params[:shopping_list_portion_id])).first
		end

		recipe_ids = []
		ingredient_ids = []

		if combi_portion.present?
			combi_portion.planner_shopping_list_portions.each do |portion|
				if portion.planner_recipe.recipe_id
					recipe_ids.push(portion.planner_recipe.recipe_id)
				else
					ingredient_ids.push(combi_portion.ingredient_id)
				end
			end
			convert_portions_to_stock(combi_portion.planner_shopping_list_portions, processing_type)
			combi_portion.update_attributes(checked: !combi_portion.checked)
		end
		if individual_portion.present?
			if individual_portion.planner_recipe.recipe_id
				recipe_ids.push(individual_portion.planner_recipe.recipe_id)
			else
				ingredient_ids.push(individual_portion.ingredient_id)
			end
			convert_portions_to_stock(individual_portion, processing_type)

			if recipe_ids.length > 0
				update_recipe_stock_matches_core(nil, current_user.id, recipe_ids)
			elsif ingredient_ids.length > 0
				update_recipe_stock_matches_core(ingredient_ids, current_user.id)
			end
		end

		current_user.planner_shopping_lists.first.update_attributes(
			ready: true
		)


	end

	def convert_portions_to_stock(portions, processing_type)
		portions_array = [].push(portions).flatten

		cupboard_id = current_user.cupboard_users.where(accepted: true).select{|cu| cu.cupboard.setup == false && cu.cupboard.hidden == false }.map{|cu| cu.cupboard }.sort_by{|c| c.updated_at}.first.id
		portions_array.each do |portion|
			recipe_stock = Stock.find_or_create_by(
				ingredient_id: portion.ingredient_id,
				amount: portion.amount,
				planner_recipe_id: portion.planner_recipe_id,
				unit_id: portion.unit_id,
				use_by_date: Date.current + 2.weeks,
				cupboard_id: cupboard_id,
				always_available: false,
				planner_shopping_list_portion_id: portion.id
			)
			current_user.stocks << recipe_stock
			if processing_type && processing_type == 'remove_portion'
				recipe_stock.update_attributes(hidden: true)
			end
			if processing_type && processing_type == 'add_portion'
				recipe_stock.update_attributes(hidden: false)
			end
			portion.update_attributes(checked: !portion.checked)
		end

	end

end

