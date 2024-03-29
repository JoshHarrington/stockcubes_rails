module RecipesHelper

	def vegan?(recipe)
		if recipe.ingredients.none?{ |ingredient| ingredient.vegan == false }
			return true
		end
	end
	def vegetarian?(recipe)
		if recipe.ingredients.none?{ |ingredient| ingredient.vegetarian == false }
			return true
		end
	end
	def gluten_free?(recipe)
		if recipe.ingredients.none?{ |ingredient| ingredient.gluten_free == false }
			return true
		end
	end
	def dairy_free?(recipe)
		if recipe.ingredients.none?{ |ingredient| ingredient.dairy_free == false }
			return true
		end
	end
	def kosher?(recipe)
		if recipe.ingredients.none?{ |ingredient| ingredient.kosher == false }
			return true
		end
	end
	def portion_amount_unit_and_ingredient(portion)

		## check if ingredient unit is correct unit, fallback to portion unit if different
		if portion.unit_id == portion.ingredient.unit_id
			if portion.ingredient.unit.short_name
				portion_unit = portion.ingredient.unit.short_name.downcase
			else
				portion_unit = portion.ingredient.unit.name
			end
		else
			correct_unit = portion.unit
			if correct_unit.short_name
				portion_unit = correct_unit.short_name.downcase
			else
				portion_unit = correct_unit.name
			end
		end

		portion_amount = portion.amount
		ingredient = portion.ingredient.name

		if portion_amount == 0.33
			portion_amount = 1/3.to_r
		elsif portion_amount == 0.67
			portion_amount = 2/3.to_r
		end

		if (portion_amount.to_f % 1 == 0)
			portion_amount = portion_amount.to_i
		elsif (portion_amount.to_r > 1)
			# portion_amount = portion.amount.to_r
			portion_amount = portion_amount.to_r.to_whole_fraction
			portion_amount = portion_amount[0].to_s + " <sup>" + portion_amount[1].to_s + "</sup>/<sub>" + portion_amount[2].to_s + "</sub>"
		else
			portion_amount = portion_amount.to_r.to_s
			portion_amount = portion_amount.split('/')
			portion_amount = " <sup>" + portion_amount[0].to_s + "</sup>/<sub>" + portion_amount[1].to_s + "</sub>"
		end


		if portion_unit == "Each"
			## figure out pluralization at same time, based on portion amount
			portion_amount.to_s + ' ' + ingredient.pluralize(portion_amount.to_i)
		else
			pluralize(portion_amount, portion_unit.to_s.titleize) + ' ' + ingredient.to_s
		end
	end

	def cuisines_list()
		return ["American", "British", "Caribbean", "Chinese", "French", "Greek", "Indian", "Italian", "Japanese", "Mediterranean", "Mexican", "Moroccan", "Spanish", "Thai", "Turkish", "Vietnamese"]
	end

	def publishable_state_check(recipe: nil)
		return nil if recipe == nil

		if !recipe.title.blank? &&
				recipe.steps.length > 0 &&
				!recipe.steps.first.content.blank? &&
				recipe.cook_time != nil &&
				recipe.portions.length > 0
			## Recipe is publishable

			return true
		else
			## Recipe is not publishable
			return false
		end
	end

	def recipe_exists_and_can_be_edited(recipe_id: nil, user: nil)
		return nil if recipe_id == nil || user == nil
		if Recipe.exists?(recipe_id.to_f) && (user.admin || user.recipes.map(&:id).include?(recipe_id.to_f))
			return true
		else
			return false
		end
	end

end
