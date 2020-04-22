module CupboardHelper
	def use_by_date(stock)
		days_from_now = (stock.use_by_date - Date.current).to_i
		weeks_from_now = (days_from_now / 7).floor
		months_from_now = (days_from_now / 30).floor
		if stock.use_by_date.today?
			return "Going out of date today!"
		elsif stock.use_by_date.future?
			if days_from_now > 30
				return "Use by date is more than " + pluralize(months_from_now, "month") + " away"
			elsif days_from_now > 6
				return "Use by date is more than " + pluralize(weeks_from_now, "week") + " away"
			else
				return "Use by date is " + pluralize(days_from_now, "day") + " away"
			end
		elsif days_from_now > -2
			return "Just out of date"
		else
			return "Out of date"
		end
	end
	def date_warning_class(stock)
		days_from_now = (stock.use_by_date - Date.current).to_i
		if days_from_now < 2 && days_from_now > -2
			return ' date-part-warning'
		elsif days_from_now <= -2
			return ' date-full-warning'
		end
	end
	def stock_unit(stock)
		return stock.unit
	end
	def cupboard_shared_class(cupboard)
		if cupboard.cupboard_users.length > 1
			return 'shared'
		end
	end
	def cupboard_empty_class(cupboard)
		stock_num = cupboard.stocks.select{|s| s.planner_recipe == nil && s.hidden == false && s.ingredient.name.downcase.to_s != "water" && s.use_by_date > Date.current - 4.day}.length
		if stock_num < 1
			return 'empty'
		end
	end
	def cupboard_stocks_selection_in_date(cupboard)
		@stocks = cupboard.stocks.select{|s| s.planner_shopping_list_portion_id == nil && s.hidden == false && s.ingredient.name.downcase != 'water' && s.use_by_date > Date.current - 4.day}.sort_by{|s| s.use_by_date}
		return @stocks
	end
	def planner_stocks(planner_recipe)
		stock_from_planner_portions = planner_recipe.planner_shopping_list_portions
			.map{|p| p.stock}.compact
			.select{|s|s.hidden == false && s.always_available == false && s.use_by_date > Date.current - 4.day}
			.sort_by{|s| s.use_by_date}
		return stock_from_planner_portions
	end

	def percentage_of_portion_in_stock(stock = nil)
		return 0 if stock == nil

		portion = stock.planner_shopping_list_portion
		return 0 if portion == nil

		return 0 if stock.ingredient_id != portion.ingredient_id
		return 0 if stock.unit.unit_type != portion.unit.unit_type

		if stock.unit.unit_type != nil

			metric_stock_amount = standardise_amount_with_metric_ratio(stock.amount, stock.unit.metric_ratio)
			metric_portion_amount = standardise_amount_with_metric_ratio(portion.amount, portion.unit.metric_ratio)

			portion_in_stock_percentage = (metric_stock_amount / metric_portion_amount.to_f) * 100

			if portion_in_stock_percentage > 100
				return 100
			else
				return portion_in_stock_percentage.round()
			end
		else
			return 0 if stock.unit_id != portion.unit_id

			portion_in_stock_percentage = (stock.amount / portion.amount.to_f) * 100

			if portion_in_stock_percentage > 100
				return 100
			else
				return portion_in_stock_percentage.round()
			end
		end

	end

	def user_cupboards(user = nil)
		return if user == nil
		return user.cupboard_users.where(accepted: true).select{|cu| cu.cupboard.setup == false && cu.cupboard.hidden == false }.map{|cu| cu.cupboard }.sort_by{|c| c.created_at}.reverse!
	end
	def first_cupboard(user = nil)
		return user_cupboards(user).first
	end

	def needed_stock(planner_recipe)
		planner_stock_ingredient_ids = planner_stocks(planner_recipe).map(&:ingredient_id).uniq
		return planner_recipe.recipe.portions.where.not(ingredient_id: planner_stock_ingredient_ids)
	end

	def recipe_portions_checked_portions(planner_recipe)
		return {
			recipe_portions_in_stock: planner_stocks(planner_recipe).length,
			recipe_portion_total: planner_recipe.recipe.portions.select{|p|p.ingredient.name.downcase != 'water'}.length
		}
	end

	def recipe_portions_in_stock_vs_total_float(planner_recipe)
		recipe_portions_checked_portions_hash = recipe_portions_checked_portions(planner_recipe)
		return recipe_portions_checked_portions_hash[:recipe_portions_in_stock] / recipe_portions_checked_portions_hash[:recipe_portion_total].to_f
	end

	def recipe_portions_in_stock_vs_total_percentage(planner_recipe)
		return recipe_portions_in_stock_vs_total_float(planner_recipe) * 100
	end
end
