module PlannerShoppingListHelper
	include IngredientsHelper

	def sort_all_planner_portions_by_date(planner_shopping_list = nil)
		## Get all planner portions
		all_planner_portions = planner_shopping_list.planner_shopping_list_portions

		## sort by date to find portion needed soonest
		sorted_planner_portions = all_planner_portions.sort_by{|p|p.date}
	end

	def combine_existing_similar_stock(user = nil)
		return if user == nil

		Rails.logger.debug "combine_existing_similar_stock"

		cupboards = user_cupboards(user)
		cupboard_id = cupboards.first.id

		user_stock = user.stocks.where(cupboard_id: cupboards.map(&:id))
			.group_by{|s|s.ingredient_id}.select{|i_id, v| v.length > 1 }.values.flatten

		combine_stock_group(user_stock, user)

	end

	def combine_stock_group(stock_group = nil, user = nil)
		return if stock_group == nil || user == nil

		cupboard_id = user_cupboards(user).first.id

		Rails.logger.debug "combine_stock_group stock_group #{stock_group.map(&:id)}"

		similar_stocks_group_for_metric = stock_group
			.select{|s|
				s.unit.unit_type != nil && s.planner_shopping_list_portion_id == nil && s.hidden == false
			}.group_by{|s| [s.ingredient_id, s.unit.unit_type]}
		matching_metric_stock_hash = similar_stocks_group_for_metric.select{|(i, ut),v| v.length > 1 }

		matching_metric_stock_hash.each do |(ingredient_id, unit_type), stocks|
			stock_amount_array = stocks.map{ |s|
				standardise_amount_with_metric_ratio(s.amount, s.unit.metric_ratio)
			}
			stock_amount = sum_stock_amounts(stock_amount_array)

			use_by_date = stocks.sort_by{|s|s.use_by_date}.first.use_by_date
			unit_id = Unit.find_by(metric_ratio: 1, unit_type: unit_type).id

			new_stock_create(user, stock_amount, unit_id, use_by_date, ingredient_id, cupboard_id)

			stocks.map{|s| s.destroy}
		end

		similar_stocks_group_for_non_metric = stock_group
			.select{|s|
				s.unit.unit_type == nil && s.planner_shopping_list_portion_id == nil && s.hidden == false
			}.group_by{|s| [s.ingredient_id, s.unit_id]}
		matching_non_metric_stock_hash = similar_stocks_group_for_non_metric.select{|(i, uid),v| v.length > 1}

		matching_non_metric_stock_hash.each do |(ingredient_id, unit_id), stocks|
			summed_stock_amount = stocks.map{|s|s.amount}.sum
			use_by_date = stocks.sort_by{|s|s.use_by_date}.first.use_by_date

			new_stock_create(user, summed_stock_amount, unit_id, use_by_date, ingredient_id, cupboard_id)

			stocks.map{|s| s.destroy}
		end

	end

	def new_stock_create(user = nil, amount = nil, unit_id = nil, use_by_date = nil, ingredient_id = nil, cupboard_id = nil, portion = nil)
		return if user == nil || amount == nil || unit_id == nil || use_by_date == nil || ingredient_id == nil || cupboard_id == nil

		new_stock = Stock.create(
			amount: amount,
			unit_id: unit_id,
			cupboard_id: cupboard_id,
			hidden: false,
			always_available: false,
			use_by_date: use_by_date,
			ingredient_id: ingredient_id,
			planner_recipe_id: portion ? portion.planner_recipe_id : nil,
			planner_shopping_list_portion_id: portion ? portion.id : nil
		)
		StockUser.create(
			stock_id: new_stock.id,
			user_id: user.id
		)
	end

	def standardise_amount_with_metric_ratio(amount = nil, metric_ratio = nil)
		return if amount == nil || metric_ratio == nil

		return amount * metric_ratio
	end

	def sum_stock_amounts(amounts_array = [])
		return if amounts_array == [] || amounts_array.length == 0
		return amounts_array.sum
	end

	def find_matching_stock_for_portion(portion = nil)
		return if portion == nil

		Rails.logger.debug "find_matching_stock_for_portion"

		user = portion.user
		cupboards = user_cupboards(user)
		user_stock = user.stocks.where(cupboard_id: cupboards.map(&:id))

		## only get stock that isn't associated to a planner portion
		available_stock = user_stock
			.select{|s| s.hidden == false && s.planner_shopping_list_portion_id == nil &&
				s.ingredient_id == portion.ingredient_id}

		Rails.logger.debug "available_stock #{available_stock.map(&:id)}"

		return if available_stock.length == 0

		### check if portion is metric
		if portion.unit.unit_type != nil

			Rails.logger.debug "portion.unit.unit_type != nil"

			subsection_of_available_metric_stock = available_stock.select{|s|s.unit.unit_type != nil}

			if subsection_of_available_metric_stock.length > 1
				Rails.logger.debug "subsection_of_available_metric_stock.length > 1"

				combine_stock_group(subsection_of_available_metric_stock, user)

				## if not passing the stock back in at this point then need to run function again
				## this way there should only be max 1 stock to compare against
				find_matching_stock_for_portion(portion)
			elsif subsection_of_available_metric_stock.length == 1

				Rails.logger.debug "subsection_of_available_metric_stock.length == 1"

				comparable_stock = subsection_of_available_metric_stock.first

				metric_stock_amount = standardise_amount_with_metric_ratio(comparable_stock.amount, comparable_stock.unit.metric_ratio)
				metric_portion_amount = standardise_amount_with_metric_ratio(portion.amount, portion.unit.metric_ratio)

				metric_unit = Unit.find_by(metric_ratio: 1, unit_type: portion.unit.unit_type)

				if metric_stock_amount >= metric_portion_amount

					## create new stock from portion
					new_stock_create(user, portion.amount, portion.unit_id, comparable_stock.use_by_date, portion.ingredient_id, cupboards.first.id, portion)

					if metric_stock_amount == metric_portion_amount
						comparable_stock.destroy
					else
						## reduce comparable stock amount by proportional amount
						comparable_stock.update_attributes(
							planner_shopping_list_portion_id: portion.id,
							unit_id: metric_unit.id,
							amount: metric_stock_amount - metric_portion_amount
						)
					end

					portion.update_attributes(
						checked: true
					)

				else

					Rails.logger.debug "metric_stock_amount < metric_portion_amount"

					stock_amount = comparable_stock.amount / portion.unit.metric_ratio

					comparable_stock.update_attributes(
						planner_shopping_list_portion_id: portion.id,
						amount: stock_amount,
						unit_id: portion.unit_id,
						planner_recipe_id: portion.planner_recipe_id
					)

					Rails.logger.debug "comparable_stock #{comparable_stock.id}"

					### could add extra column to planner portion table to record amount in stock
					### right now just need to do check on what stock associated to planner portion
					### and report on what percentage of that planner portion amount is in stock

				end
			end



		## otherwise portion not metric
		else

			subsection_of_available_stock_non_metric = available_stock.select{|s|s.unit.unit_type == nil && s.unit_id == portion.unit_id}

			if subsection_of_available_stock_non_metric.length > 1
				combine_stock_group(subsection_of_available_stock_non_metric, user)

				## if not passing the stock back in at this point then need to run function again
				## this way there should only be max 1 stock to compare against
				find_matching_stock_for_portion(portion)
			elsif subsection_of_available_stock_non_metric.length == 1

				comparable_stock = subsection_of_available_stock_non_metric.first

				stock_amount = comparable_stock.amount
				portion_amount = portion.amount

				if stock_amount >= portion_amount
					## create new stock from portion
					new_stock_create(user, portion.amount, portion.unit_id, comparable_stock.use_by_date, portion.ingredient_id, cupboards.first.id, portion)

					if stock_amount == portion_amount
						comparable_stock.destroy
					else
						## reduce comparable stock amount by proportional amount
						comparable_stock.update_attributes(
							amount: stock_amount - portion_amount
						)
					end

					portion.update_attributes(
						checked: true
					)

				else

					comparable_stock.update_attributes(
						planner_shopping_list_portion_id: portion.id,
						planner_recipe_id: portion.planner_recipe_id
					)

					### could add extra column to planner portion table to record amount in stock
					### right now just need to do check on what stock associated to planner portion
					### and report on what percentage of that planner portion amount is in stock

				end
			end
		end
	end

	### STEPS
	## [/] find all portions, order by date [sort_all_planner_portions_by_date]
	## [/] combine all similar stock in the same cupboard [combine_existing_similar_stock]
	## [/] for each portion, check if similar stock exists [find_matching_stock_for_portion]
	## [/] if similar stock exists - is there enough of it to fill planner portion need
	## [/] if yes (whole amount or more), mark planner portion as checked
	##      and create new stock with whole planner portion amount
	##      and mark as associated to that planner portion
	##      remove total amount of planner portion from existing stock
	## [/] if yes (partial amount)
	##			update similar stock with planner portion id and planner recipe id
	##			add note in shopping list with amount still needed for planner portion
	##			set percentage filled amount for stock associated to planner portion


	def _add_planner_recipe_to_shopping_list(planner_recipe = nil)
		return if planner_recipe == nil
		planner_shopping_list = PlannerShoppingList.find_or_create_by(user_id: current_user.id)

		recipe_portions = planner_recipe.recipe.portions.reject{|p| p.ingredient.name.downcase == 'water'}
		puts "recipe_portions" + recipe_portions.to_s
		ingredients_from_recipe_portions = recipe_portions.map(&:ingredient_id)

		cupboards = CupboardUser.where(user_id: current_user.id, accepted: true).map{|cu| cu.cupboard unless cu.cupboard.setup == true || cu.cupboard.hidden == true }.compact.sort_by{|c| c.created_at}.reverse!
		stock = cupboards.map{|c| c.stocks.select{|s| s.use_by_date > Date.current - 4.days && s.ingredient.name.downcase != 'water' && s.planner_recipe_id == nil && s.hidden == false }}.flatten.compact
		ingredients_from_stock = stock.map(&:ingredient_id)

		uncommon_ingredients = ingredients_from_recipe_portions - ingredients_from_stock

		if ingredients_from_recipe_portions && ingredients_from_stock.length > 0
			common_ingredients = ingredients_from_recipe_portions & ingredients_from_stock

			common_ingredients.each do |ing|
				## find the highest amount of stock ?
				stock_from_ing = stock.select{|s| s.ingredient_id == ing}.first

				portions_from_ing = recipe_portions.select{|p| p.ingredient_id == ing}

				portions_sum_from_ing = {}
				if portions_from_ing.length == 0
					next
				else
					portions_sum_from_ing = serving_addition(portions_from_ing)
				end

				puts "portions_sum_from_ing"
				puts portions_sum_from_ing

				serving_diff = serving_difference([stock_from_ing, portions_sum_from_ing])

				use_by_date_diff = get_ingredient_use_by_date_diff(Ingredient.find(ing))

				if serving_diff != false
					serving_diff_amount = serving_diff[:amount]
					if serving_diff_amount <= 0
						stock_from_ing.update_attributes(
							planner_recipe_id: planner_recipe.id
						)
						## original stock updated
						if serving_diff_amount < 0
							## when amount < 0 new stock is needed so shopping list portion should be created at the same time
							PlannerShoppingListPortion.create(
								user_id: current_user.id,
								planner_recipe_id: planner_recipe.id,
								ingredient_id: ing,
								unit_id: serving_diff[:unit_id],
								amount: -(serving_diff_amount),
								planner_shopping_list_id: planner_shopping_list.id,
								date: planner_recipe.date + use_by_date_diff.days
							)
						end
					elsif serving_diff_amount > 0
						recipe_stock = Stock.create(
							ingredient_id: ing,
							amount: serving_converter(portions_sum_from_ing)[:amount],
							planner_recipe_id: planner_recipe.id,
							unit_id: serving_diff[:unit_id],
							use_by_date: stock_from_ing.use_by_date,
							cupboard_id: stock_from_ing.cupboard_id,
							hidden: false,
							always_available: false
						)
						current_user.stocks << recipe_stock
						serving_hash = {
							metric_ratio: stock_from_ing.unit.metric_ratio,
							unit_type: stock_from_ing.unit.unit_type,
							amount: serving_diff_amount
						}

						stock_from_ing.update_attributes(
							unit_id: serving_diff[:unit_id],
							amount: serving_diff_amount
						)
					end
				else
					uncommon_ingredients.push(ing)
				end
			end
		end

		uncommon_ingredients.each do |uc_ing|
			recipe_portions.select{|p| p.ingredient_id == uc_ing}.each do |portion|
				PlannerShoppingListPortion.create(
					user_id: current_user.id,
					planner_recipe_id: planner_recipe.id,
					ingredient_id: portion.ingredient_id,
					unit_id: portion.unit_id,
					amount: portion.amount,
					planner_shopping_list_id: planner_shopping_list.id,
					date: planner_recipe.date + 2.weeks
				)
			end
		end

	end

	def setup_wrapper_portions(portion = nil, amount = nil, unit_id = nil, current_user = nil, planner_shopping_list_id = nil)
		return if portion == nil || amount == nil || unit_id == nil || user_signed_in? == false || planner_shopping_list_id == nil

		wrapper_portion = PlannerPortionWrapper.find_or_create_by(
			user_id: current_user[:id],
			planner_shopping_list_id: planner_shopping_list_id,
			ingredient_id: portion.ingredient_id
		)
		wrapper_portion.update_attributes(
			amount: amount,
			unit_id: unit_id,
			checked: portion.checked,
			date: portion.date
		)

		PlannerPortionWrapper.where(
			user_id: current_user[:id],
			planner_shopping_list_id: planner_shopping_list_id,
			ingredient_id: portion.ingredient_id
		).where.not(id: wrapper_portion[:id]).destroy_all

		PlannerShoppingListPortion.where(id: portion.id).update_all(
			planner_portion_wrapper_id: wrapper_portion[:id]
		)
		CombiPlannerShoppingListPortion.where(id: portion.id).update_all(
			planner_portion_wrapper_id: wrapper_portion[:id]
		)

	end

	def refresh_all_planner_portions(planner_shopping_list = nil)
		return if planner_shopping_list == nil

		## Loop over all planner recipes
		planner_shopping_list.planner_recipes.each do |pr|

			## Ignore old planner recipes
			next if pr.date < Date.current

			## Loop over all associated recipe portions
			pr.recipe.portions.each do |rp|

				## Ignore water portions
				next if rp.ingredient.name.downcase == 'water'

				## Create new planner portions using the recipe portion as template
				PlannerShoppingListPortion.find_or_create_by(
					user_id: planner_shopping_list.user_id,
					planner_recipe_id: pr.id,
					ingredient_id: rp.ingredient_id,
					planner_shopping_list_id: planner_shopping_list.id
				).update_attributes(
					unit_id: rp.unit_id,
					amount: rp.amount,
					date: pr.date + get_ingredient_use_by_date_diff(rp.ingredient)
				)

				#### TODO - check if stock already exists?
				####				or can be taken from cupboards
				####				if yes then setup planner portion with checked state

			end
		end
	end

	def delete_all_combi_planner_portions_and_create_new(planner_shopping_list_id = nil)
		return if planner_shopping_list_id == nil

		planner_shopping_list = PlannerShoppingList.find(planner_shopping_list_id)

		Rails.logger.debug "delete_all_combi_planner_portions_and_create_new"
		## Delete all planner combi portions
		planner_shopping_list.combi_planner_shopping_list_portions.destroy_all

		Rails.logger.debug planner_shopping_list.planner_shopping_list_portions.group_by{|p| p.ingredient_id}.select{|k,v| v.length > 1}

		## Find all planner portions with same ingredient
		planner_shopping_list.planner_shopping_list_portions.group_by{|p| p.ingredient_id}.select{|k,v| v.length > 1}.each do |ing_id, portion_group|

			Rails.logger.debug "portion_group #{portion_group}"

			combi_amount = serving_addition(portion_group)
			combi_portion = CombiPlannerShoppingListPortion.create(
				user_id: planner_shopping_list.user_id,
				planner_shopping_list_id: planner_shopping_list.id,
				ingredient_id: ing_id,
				amount: combi_amount ? combi_amount[:amount] : nil,
				unit_id: combi_amount ? combi_amount[:unit_id] : nil,
				date: portion_group.sort_by{|p| p.planner_recipe.date}.first.date,
				checked: portion_group.count{|p| p.checked == false} > 0 ? false : true
			)

			portion_group.each do |p|
				p.update_attributes(
					combi_planner_shopping_list_portion_id: combi_portion.id
				)
			end

		end

			### TODO --- instead of always trying to figure out what to items added together is for combi portion
			### 			   could just show those two amounts grouped eg Carrots [100g + 2 small]
			### 				 if combi portion amount is nil, output individual portion amount instead?
			###			 --- Render combi portion as wrapper/parent to other portions
			###					 - if combi portion amount is known then show it and hide other portions,
			###					 other portions can be shown and checked individually
			###							if combi portion is checked - both other portions are checked also
			###					 - if combi portion not know, still wrapped with combi portion,
			### 					but expanded to show other portion amounts

	end

	def update_planner_shopping_list_portions
		return if user_signed_in? == false
		planner_shopping_list = PlannerShoppingList.find_or_create_by(user_id: current_user.id)
		if current_user.planner_recipes && current_user.planner_recipes.length == 0
			current_user.combi_planner_shopping_list_portions.destroy_all
			planner_shopping_list.update_attributes(
				ready: true
			)
			return
		end


		refresh_all_planner_portions(planner_shopping_list)

		sorted_planner_portions = sort_all_planner_portions_by_date(planner_shopping_list)

		sorted_planner_portions.each do |portion|
			find_matching_stock_for_portion(portion)
		end

		delete_all_combi_planner_portions_and_create_new(planner_shopping_list.id)

		combine_existing_similar_stock(current_user)


		#### TODO -- figure out how wrapper portions can work alongside developed combi portions

		# all_shopping_list_portions = []
		# planner_shopping_list_portions.reject{|p| p.combi_planner_shopping_list_portion_id != nil}.map{|p| all_shopping_list_portions.push(p)}
		# current_user.combi_planner_shopping_list_portions.select{|cp|cp.date >= Date.current}.map{|cp|all_shopping_list_portions.push(cp)}

		# all_shopping_list_portions.each do |p|

		# 	size_diff = false

		# 	# loop over each default ingredient size to find a size bigger than the portion
		# 	# if no size found, double the ingredient size amounts then rerun the loop
		# 	# keep stepping up sizes until correct size found


		# 	planner_portion_size = find_planner_portion_size(p)

		# 	next if planner_portion_size == false

		# 	amount = planner_portion_size[:converted_size][:amount]
		# 	unit_id = planner_portion_size[:converted_size][:unit_id]

		# 	setup_wrapper_portions(p, amount, unit_id, current_user, planner_shopping_list.id)

		# end

	end


	def combine_divided_stock_after_planner_recipe_delete(planner_recipe = nil)
		return if planner_recipe == nil || planner_recipe.stocks.length < 1
		planner_recipe.stocks.each do |stock|
			stock_partner = stock.cupboard.stocks.where.not(id: stock.id).find_by(ingredient_id: stock.ingredient_id, use_by_date: stock.use_by_date)
			return unless stock_partner.present?
			return if stock_partner.updated_at > Date.current - 10.minutes
			stock_group = [stock_partner, stock]
			if serving_addition(stock_group)
				stock_addition_hash = serving_addition(stock_group)
				stock_amount = stock_addition_hash[:amount]
				stock_unit_id = stock_addition_hash[:unit_id]
				stock_partner.update_attributes(
					amount: stock_amount,
					unit_id: stock_unit_id
				)
				stock.delete
			else
				stock.update_attributes(
					planner_recipe_id: nil
				)
			end

		end
	end

	def shopping_list_portions(shopping_list = nil)
		if shopping_list == nil && current_user && current_user.planner_shopping_list.present?
			shopping_list = current_user.planner_shopping_list
		elsif shopping_list == nil && user_signed_in? == false
			return []
		elsif user_signed_in? && current_user.planner_shopping_list.present?
			shopping_list = PlannerShoppingList.find_or_create_by(user_id: current_user.id)
		end

		planner_recipe_portions = []
		planner_portions_with_wrap = []
		if shopping_list && shopping_list.planner_recipes && shopping_list.planner_recipes.length > 0
			all_planner_recipe_portions = shopping_list.planner_recipes.select{|pr| pr.date > Date.current - 6.hours && pr.date < Date.current + 7.day}.map{|pr| pr.planner_shopping_list_portions.reject{|p| p.combi_planner_shopping_list_portion_id != nil}.reject{|p| p.ingredient.name.downcase == 'water'}.reject{|p| p.checked == true && p.updated_at < Time.current - 1.day}}.flatten
			planner_recipe_portions = all_planner_recipe_portions.reject{|p|p.planner_portion_wrapper_id != nil}
			planner_portions_with_wrap = all_planner_recipe_portions.reject{|p|p.planner_portion_wrapper_id == nil}
		end

		combi_portions = []
		combi_portions_with_wrap = []
		if shopping_list && shopping_list.combi_planner_shopping_list_portions && shopping_list.combi_planner_shopping_list_portions.length > 0
			# all_combi_portions = shopping_list.combi_planner_shopping_list_portions.select{|c|c.date > Date.current - 6.hours && c.date < Date.current + 7.day}.reject{|cp| cp.checked == true && cp.updated_at < Time.current - 1./day}
			all_combi_portions = shopping_list.combi_planner_shopping_list_portions
			combi_portions = all_combi_portions.reject{|cp|cp.planner_portion_wrapper_id != nil}
			combi_portions_with_wrap = all_combi_portions.reject{|cp|cp.planner_portion_wrapper_id == nil}
		end

		portion_wrappers = []
		if shopping_list && shopping_list.planner_portion_wrappers && shopping_list.planner_portion_wrappers.length > 0
			wrapped_portions = combi_portions_with_wrap + planner_portions_with_wrap
			portion_wrappers = wrapped_portions.map{|p|p.planner_portion_wrapper}
		end


		shopping_list_portions = combi_portions + planner_recipe_portions + portion_wrappers
		session[:sl_checked_portions_count] = shopping_list_portions.count{|p|p.checked == true}
		session[:sl_unchecked_portions_count] = shopping_list_portions.count{|p|p.checked == false}
		session[:sl_total_portions_count] = shopping_list_portions.count

		Rails.logger.debug "combi_portions"
		Rails.logger.debug combi_portions

		return shopping_list_portions.sort_by!{|p| p.ingredient.name}

	end

	def unchecked_portions
		add_portion_counts_to_session
		return session[:sl_unchecked_portions_count]
	end

	def checked_portions
		add_portion_counts_to_session
		return session[:sl_checked_portions_count]
	end

	def total_portions
		add_portion_counts_to_session
		return session[:sl_total_portions_count]
	end

	def user_recipe_stock_match_check(recipe_id = nil)
		return nil if user_signed_in? == false || recipe_id == nil
		return UserRecipeStockMatch.find_by(user_id: current_user.id, recipe_id: recipe_id)
	end

	def retrieve_recipe_stock_match_detail(recipe = nil, key = nil)
		return 0 if recipe == nil || key == nil || user_signed_in? == false

		user_recipe_stock_match = user_recipe_stock_match_check(recipe.id)
		return 0 if user_recipe_stock_match == nil

		match_detail = user_recipe_stock_match[key]
		return 0 if match_detail == nil
		return match_detail
	end

	def percent_in_cupboards(recipe = nil)
		ingredient_stock_match_decimal = retrieve_recipe_stock_match_detail(recipe, :ingredient_stock_match_decimal)
		return ingredient_stock_match_decimal != nil ? (ingredient_stock_match_decimal.to_f * 100).round : 0
	end

	def num_stock_ingredients(recipe = nil)
		return retrieve_recipe_stock_match_detail(recipe, :num_stock_ingredients)
	end

	def num_needed_ingredients(recipe = nil)
		return retrieve_recipe_stock_match_detail(recipe, :num_needed_ingredients)
	end

	def add_portion_counts_to_session
		unless session.has_key?(:sl_checked_portions_count)
			shopping_list_portions_var = shopping_list_portions
			session[:sl_checked_portions_count] = shopping_list_portions_var.count{|p|p.checked == true}
			session[:sl_unchecked_portions_count] = shopping_list_portions_var.count{|p|p.checked == false}
			session[:sl_total_portions_count] = shopping_list_portions_var.count
		end
	end

	def planner_portion_id_hash
		return Hashids.new(ENV['PLANNER_PORTIONS_SALT'])
	end

	def current_planner_recipe_ids
		return [] if user_signed_in? == false
		# if session.has_key?(:current_planner_recipe_ids)
		# 	Rails.logger.debug "session[:current_planner_recipe_ids] - "
		# 	Rails.logger.debug session[:current_planner_recipe_ids]
		# 	return session[:current_planner_recipe_ids]
		# else
		# 	update_current_planner_recipe_ids
		# 	current_planner_recipe_ids
		# end
		return current_user.planner_recipes.where(date: Date.current..Date.current+7.days).map(&:recipe_id)
	end

	def update_current_planner_recipe_ids
		if user_signed_in?
			session[:current_planner_recipe_ids] = current_user.planner_recipes.where(date: Date.current..Date.current+7.days).map(&:recipe_id)
		end
	end

	def update_portion_details(params)

		if params.has_key?(:gen_id) && PlannerShoppingList.find_by(gen_id: params[:gen_id])
			shopping_list = PlannerShoppingList.find_by(gen_id: params[:gen_id])
		elsif current_user
			shopping_list = current_user.planner_shopping_list
		else
			return
		end

		return unless params.has_key?(:shopping_list_portion_id) && params.has_key?(:portion_type)
		shopping_list.update_attributes(
			ready: false
		)

		planner_portion = nil

		if params[:portion_type] == 'combi_portion'
			planner_portion = shopping_list.combi_planner_shopping_list_portions.find(planner_portion_id_hash.decode(params[:shopping_list_portion_id])).first
		elsif params[:portion_type] == 'individual_portion'
			planner_portion = shopping_list.planner_shopping_list_portions.find(planner_portion_id_hash.decode(params[:shopping_list_portion_id])).first
		elsif params[:portion_type] == 'wrapper_portion'
			planner_portion = shopping_list.planner_portion_wrappers.find(planner_portion_id_hash.decode(params[:shopping_list_portion_id])).first.planner_shopping_list_portion
		end


		if planner_portion != nil
			planner_portion.update_attributes(date: params[:date])
			setup_wrapper_portions(planner_portion, params[:amount], params[:unit_id], current_user, shopping_list.id)
		end


		shopping_list.update_attributes(
			ready: true
		)

	end
end
