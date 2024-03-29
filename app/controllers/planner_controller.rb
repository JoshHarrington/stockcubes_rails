class PlannerController < ApplicationController
	before_action :authenticate_user!, except: [:list, :update_portion, :get_shopping_list_content]
	include PlannerShoppingListHelper
	include ServingHelper
	include UnitsHelper
	include CupboardHelper

	include PortionStockHelper

	def index
		@recipe_id_hash = Hashids.new(ENV['RECIPE_ID_SALT'])
		@planner_recipe_date_hash = Hashids.new(ENV['PLANNER_RECIPE_DATE_SALT'])
		@recipes = current_user.user_recipe_stock_matches.order(ingredient_stock_match_decimal: :desc).reject{|u_r| current_planner_recipe_ids.include?(u_r.recipe_id) }.select{|u_r| u_r.recipe && u_r.recipe.portions.length != 0 && (u_r.recipe[:public] || u_r.recipe[:user_id] == current_user[:id])}[0..11].map{|u_r| u_r.recipe}

		recipe_id_plus_planner_recipe_ids = @recipes.map(&:id) + current_planner_recipe_ids
		@fav_recipes = current_user.favourites.reject{|f| recipe_id_plus_planner_recipe_ids.include?(f.id) }.first(8)
	end

	def list
		if params.has_key?(:gen_id) && PlannerShoppingList.find_by(gen_id: params[:gen_id]) != nil
			## shopping list found

			@shopping_list = PlannerShoppingList.find_by(gen_id: params[:gen_id])

			## redirect if no shopping list portions found
			if shopping_list_portions(@shopping_list).length == 0
				redirect_to root_path
				flash[:notice] = "Looks like there aren't any ingredients in that shopping list"
			end

		else
			## redirect to root
			redirect_to root_path

			## show message to explain redirection
			flash[:error] = "Looks like that shopping list link doesn't work"
		end

	end

	def refresh
		unless current_user
			respond_to do |format|
				format.json { render json: {'planner refresh': 'not allowed'}.as_json, status: 400}
				format.html { redirect_to planner_path }
			end and return
		end

		fetched_shopping_list_portions = shopping_list_portions(nil, current_user)

		respond_to do |format|
			format.json { render json: {
				plannerRecipes: processed_planner_recipes_with_date(current_user),
				suggestedRecipes: processed_recipe_list_for_user(current_user),
				checkedPortionCount: fetched_shopping_list_portions.count{|p|p.checked},
				totalPortionCount: fetched_shopping_list_portions.count,
				shoppingListPortions: processed_shopping_list_portions(fetched_shopping_list_portions)
			}.as_json, status: 200}
		end
	end

	def recipe_add_to_planner
		@recipe_id_hash = Hashids.new(ENV['RECIPE_ID_SALT'])
		@planner_recipe_date_hash = Hashids.new(ENV['PLANNER_RECIPE_DATE_SALT'])
		if params.has_key?(:recipe_id) && Recipe.exists?(@recipe_id_hash.decode(params[:recipe_id]).first)
			recipe = Recipe.find(@recipe_id_hash.decode(params[:recipe_id]).first)
		else
			current_user.planner_shopping_list.update_attributes(
				ready: true
			)
			respond_to do |format|
				format.json { render json: {message: 'Recipe not found'}.as_json, status: 404}
				format.html { redirect_to planner_path }
			end and return
		end

		if recipe && (recipe.public == true || recipe.user == current_user)
			recipe_id = recipe.id
			user_id = current_user.id
		else
			current_user.planner_shopping_list.update_attributes(
				ready: true
			)
			respond_to do |format|
				format.json { render json: {message: "Recipe not public / accessible for current user"}.as_json, status: 403}
				format.html { redirect_to planner_path }
			end and return
		end

		if params.has_key?(:date) && params[:date] != nil
			date_string = params[:date].to_date
		else
			this_months_dates = (Date.current..Date.current+30.days).to_a
			last_planner_recipe_dates = current_user.planner_recipes.where(date: this_months_dates).order(date: :asc).map(&:date).uniq
			available_dates = this_months_dates - last_planner_recipe_dates
			if available_dates.length > 0
				date_string = available_dates.first
			else
				date_string = last_planner_recipe_dates.last + 1.day
			end
		end

		planner_shopping_list = current_user.planner_shopping_list

		if planner_shopping_list.ready == false
			Rails.logger.debug "planner_shopping_list.ready == false"

			respond_to do |format|
				format.json { render json: {message: 'Server busy'}.as_json, status: 408}
				format.html { redirect_to planner_path }
			end and return
		end

		planner_shopping_list.update_attributes(
			ready: false
		)

		planner_recipe = PlannerRecipe.create(
			user_id: user_id,
			recipe_id: recipe_id,
			date: date_string,
			planner_shopping_list_id: planner_shopping_list.id
		)

		# if recipe.portions.length > 0
		# 	add_planner_recipe_to_shopping_list(planner_recipe)
		# end

		update_planner_shopping_list_portions()


		date_num = date_string.to_formatted_s(:number)
		date_id = @planner_recipe_date_hash.encode(date_num)
		hashed_recipe_id = @recipe_id_hash.encode(recipe_id)

		fetched_shopping_list_portions = shopping_list_portions(nil, current_user)

		planner_shopping_list.update_attributes(
			ready: true
		)

		respond_to do |format|
			format.json { render json: {
				plannerDateId: date_id,
				recipeEncodedId: hashed_recipe_id,
				recipeTitle: recipe.title,
				recipePath: recipe_path(recipe_id),
				percentInCupboards: percent_in_cupboards(recipe),
				plannerRecipes: processed_planner_recipes_with_date(current_user),
				suggestedRecipes: processed_recipe_list_for_user(current_user),
				checkedPortionCount: fetched_shopping_list_portions.count{|p|p[:checked]},
				totalPortionCount: fetched_shopping_list_portions.count,
				shoppingListPortions: processed_shopping_list_portions(fetched_shopping_list_portions)
			}.as_json, status: 200}
		end

		update_current_planner_recipe_ids

	end

	def recipe_update_in_planner
		current_user.planner_shopping_list.update_attributes(
			ready: false
		)

		planner_recipe_id_hash = Hashids.new(ENV['PLANNER_RECIPE_ID_SALT'])

		if params.has_key?(:planner_recipe_id) && PlannerRecipe.exists?(planner_recipe_id_hash.decode(params[:planner_recipe_id]).first) && params.has_key?(:new_date)
			planner_recipe = current_user.planner_recipes.find(planner_recipe_id_hash.decode(params[:planner_recipe_id]).first)
		else
			current_user.planner_shopping_list.update_attributes(
				ready: true
			)
			respond_to do |format|
				format.json { render json: {'planner recipe update': 'not allowed'}.as_json, status: 400}
				format.html { redirect_to planner_path }
			end and return
		end

		if planner_recipe.present?

			planner_recipe.update_attributes(
				date: params[:new_date].to_date
			)
			update_planner_shopping_list_portions()
		end

		current_user.planner_shopping_list.update_attributes(
			ready: true
		)

		fetched_shopping_list_portions = shopping_list_portions(nil, current_user)

		respond_to do |format|
			format.json { render json: {
				plannerRecipes: processed_planner_recipes_with_date(current_user),
				suggestedRecipes: processed_recipe_list_for_user(current_user),
				checkedPortionCount: fetched_shopping_list_portions.count{|p|p.checked},
				totalPortionCount: fetched_shopping_list_portions.count,
				shoppingListPortions: processed_shopping_list_portions(fetched_shopping_list_portions),
			}.as_json, status: 200}
			format.html { redirect_to planner_path }
		end

		update_current_planner_recipe_ids
	end

	def delete_recipe_from_planner
		current_user.planner_shopping_list.update_attributes(
			ready: false
		)

		planner_recipe_id_hash = Hashids.new(ENV['PLANNER_RECIPE_ID_SALT'])

		if params.has_key?(:planner_recipe_id) && PlannerRecipe.exists?(planner_recipe_id_hash.decode(params[:planner_recipe_id]).first)
			planner_recipe = current_user.planner_recipes.find(planner_recipe_id_hash.decode(params[:planner_recipe_id]).first)
		else
			current_user.planner_shopping_list.update_attributes(
				ready: true
			)
			respond_to do |format|
				format.json { render json: {'planner recipe delete': 'not allowed'}.as_json, status: 400}
				format.html { redirect_to planner_path }
			end and return
		end

		if planner_recipe.present?
			combine_divided_stock_after_planner_recipe_delete(planner_recipe)
			planner_recipe.destroy
			update_planner_shopping_list_portions()
		end

		current_user.planner_shopping_list.update_attributes(
			ready: true
		)

		fetched_shopping_list_portions = shopping_list_portions(nil, current_user)

		respond_to do |format|
			format.json { render json: {
				plannerRecipes: processed_planner_recipes_with_date(current_user),
				suggestedRecipes: processed_recipe_list_for_user(current_user),
				checkedPortionCount: fetched_shopping_list_portions.count{|p|p.checked},
				totalPortionCount: fetched_shopping_list_portions.count,
				shoppingListPortions: processed_shopping_list_portions(fetched_shopping_list_portions),
			}.as_json, status: 200}
			format.html { redirect_to planner_path }
		end

		update_current_planner_recipe_ids
	end

	def update_portion
		update_portion_details(params)
	end

	def get_shopping_list_content
		shopping_list = nil

		if params.has_key?(:gen_id)
			shopping_list = PlannerShoppingList.find_by(gen_id: params[:gen_id])
		elsif user_signed_in?
			shopping_list = current_user.planner_shopping_list
		else
			### probably will never get into this branch
			respond_to do |format|
				format.json { render json: {'shopping list': 'not found'}.as_json, status: 404}
				format.html { redirect_to planner_path }
			end and return
		end

		if shopping_list == nil
			respond_to do |format|
				format.json { render json: {'shopping list': 'not found'}.as_json, status: 404}
				format.html { redirect_to planner_path }
			end and return
		end

		if shopping_list.ready == false
			if shopping_list.updated_at < 30.seconds.ago
				shopping_list.update_attributes(ready: true)
			else
				respond_to do |format|
					format.json { render json: {'shopping list': 'not ready'}.as_json, status: 202}
					format.html { redirect_to planner_path }
				end and return
			end
		end

		fetched_shopping_list_portions = shopping_list_portions(shopping_list)

		email_sharing = email_sharing_mailto_list(fetched_shopping_list_portions, shopping_list.gen_id)

		if fetched_shopping_list_portions.length > 0
			formatted_shopping_list_portions = fetched_shopping_list_portions.sort_by{|p| p.ingredient.name}.map do |p|
				num_assoc_recipes = '1'
				if p.class.name == 'PlannerPortionWrapper'
					if p.combi_planner_shopping_list_portion != nil
						portion_type = 'wrapper'
						num_assoc_recipes = p.combi_planner_shopping_list_portion.planner_shopping_list_portions.length
						portion_note = 'Combi portion (' + num_assoc_recipes.to_s + ' recipes)'
					else
						portion_type = 'wrapper'
						recipe_title = p.planner_shopping_list_portion.planner_recipe.recipe.title
						portion_note = 'Recipe portion - ' + recipe_title
					end
				else
					if p.class.name == "CombiPlannerShoppingListPortion"
						portion_type = 'combi'
						num_assoc_recipes = p.planner_shopping_list_portions.length
						portion_note = 'Combi portion (' + num_assoc_recipes.to_s + ' recipes)'
					else
						portion_type = 'individual'
						portion_note = 'Recipe portion - ' + p.planner_recipe.recipe.title
					end
				end
				{
					"portion_type": portion_type,
					"portion_note": portion_note,
					"shopping_list_portion_id": planner_portion_id_hash.encode(p.id),
					"portion_description": stock_needed_serving_description(p),
					"portion_size": short_serving_size(p),
					"recipe_title": p.has_attribute?(:planner_recipe_id) && p.planner_recipe.recipe.present? ? p.planner_recipe.recipe.title.to_s : recipe_title.to_s,
					"in_stock": portion_type == "individual" && p.stock && percentage_of_portion_in_stock(p.stock) > 2 && percentage_of_portion_in_stock(p.stock) < 100 ? percentage_of_portion_in_stock(p.stock) : 0,
					"checked": p.checked,
					"show_child_portions?": portion_type == "combi" ? ((p.unit_id == nil && p.amount == nil) || (p.checked != true && p.planner_shopping_list_portions.count{|cp|cp.checked} == 0 && p.planner_shopping_list_portions.count{|cp|cp.stock != nil && percentage_of_portion_in_stock(cp.stock) <= 2} == 0 ) ? true : false ) : false,
					"child_portions": portion_type == "combi" ?
						p.planner_shopping_list_portions.map{|child_portion| {
							"portion_description": stock_needed_serving_description(child_portion),
							"portion_size": short_serving_size(child_portion),
							"recipe_title": child_portion.planner_recipe.recipe.title,
							"checked": child_portion.checked,
							"shopping_list_portion_id": planner_portion_id_hash.encode(child_portion.id),
							"portion_amount": round_if_whole(child_portion.amount),
							"in_stock": child_portion.stock && percentage_of_portion_in_stock(child_portion.stock) > 2 && percentage_of_portion_in_stock(child_portion.stock) < 100 ? percentage_of_portion_in_stock(child_portion.stock) : 0,
							"portion_date": child_portion.date.strftime("%Y-%m-%d"),
							"fresh_for": (child_portion.date - Date.today).to_i,
							"min_date": (Date.current - 2.days).strftime("%Y-%m-%d")
						}} : nil,
					"num_assoc_recipes": num_assoc_recipes,
					"ingredient_name": p.ingredient.name,
					"portion_amount": round_if_whole(p.amount),
					"portion_unit": p.unit_id,
					"portion_date": p.date.strftime("%Y-%m-%d"),
					"fresh_for": (p.date - Date.today).to_i,
					"min_date": (Date.current - 2.days).strftime("%Y-%m-%d"),
				}
			end
			shopping_list_output = [{"stats": {"checked_portions": checked_portions(), "total_portions": total_portions()}}, {"portions": formatted_shopping_list_portions }, {"gen_id": shopping_list.gen_id }, {"unit_list": unit_list()}, {"email_sharing": email_sharing}]
		else
			shopping_list_output = []
		end

		respond_to do |format|
			format.json { render json: shopping_list_output.as_json}
			format.html { redirect_to planner_path }
		end
	end
end