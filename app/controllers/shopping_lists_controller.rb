class ShoppingListsController < ApplicationController
  require 'set'
  before_action :logged_in_user
  before_action :user_has_shopping_lists, only: :index
  before_action :correct_user, only: [:show, :edit]

  def index
    @shopping_lists = current_user.shopping_lists.order('created_at DESC').paginate(:page => params[:page], :per_page => 12)
  end
	def new
    @shopping_lists = ShoppingList.new
    @recipes = Recipe.all
    @user_id = current_user.id
  end
  def create
    # Rails.logger.debug params[:shopping_list][:recipes][:id]
    @recipe_ids = params[:shopping_list][:recipes][:id]
    @user = current_user
    @user_id = current_user.id
    @recipes = Recipe.all
    @recipe_pick = Recipe.find(@recipe_ids)

    @current_date = Date.today
    @shopping_list = ShoppingList.new(shopping_list_params)

    @user.shopping_lists << @shopping_list
    @shopping_list.recipes << @recipe_pick

    shopping_list_portion_ids = []
    @shopping_list.recipes.each do |recipe|
      recipe.portions.each do |portion|
        shopping_list_portion_ids.push(portion.id)
      end
    end

    shopping_list_portion_ids.each do |portion_id|
      portion_obj = Portion.where(id: portion_id).first
      ingredient_obj = Ingredient.where(id: portion_obj.ingredient_id).first
      if ingredient_obj
        @shopping_list.ingredients << ingredient_obj
        shopping_list_portion_obj = ShoppingListPortion.where(ingredient_id: ingredient_obj.id, shopping_list_id: @shopping_list.id)
        portion_unit_obj = Unit.where(id: portion_obj.unit_number).first

        shopping_list_portion_obj.each do |shopping_list_portion|
          view_context.metric_transform_portion_update(shopping_list_portion, portion_unit_obj, portion_obj, ingredient_obj)
        end
      end
    end

    if @shopping_list.save
      redirect_to shopping_list_path(@shopping_list.id)
    else
      render 'new'
    end
  end

	def show
		@shopping_list = ShoppingList.find(params[:id])
		@recipes = @shopping_list.recipes
  end
  def show_ingredients

    @shopping_list = ShoppingList.find(params[:id])
    @recipes = @shopping_list.recipes

    @portion_ids = []
    @recipes.each do |recipe|
      recipe.portions.each do |portion|
        @portion_ids << portion.id
      end
    end
    @portions = Portion.find(@portion_ids)

    @ingredients = @shopping_list.ingredients.uniq
    @ingredient_ids = @ingredients.map(&:id)
    @user_cupboard_ids = current_user.cupboards.map(&:id)

    @stock = Stock.where(cupboard_id: @user_cupboard_ids, ingredient_id: @ingredient_ids)
    @stock_ingredient_ids = @stock.map(&:ingredient_id)
    @not_in_stock_ingredient_ids = @ingredient_ids - @stock_ingredient_ids
    ## need to flatten stock to catch where stock is split over multiple cupboards

    # @portion_names = @portion.ingredient.name.uniq

    @portions_hash = Hash.new{|hsh,key| hsh[key] = {} }

    @portions.each do |portion|
      portion_amount = 0

      portion_amount = portion.quantity.comparable_amount

      if @portions_hash.key?(portion.ingredient.name)
        portion_amount = @portions_hash[portion.ingredient.name]["portion_amount"].to_f + portion_amount
      end

      default_unit_number = portion.ingredient.unit_id
      ingredient_unit = Unit.where(unit_number: default_unit_number.to_i).first
      ingredient_unit_name = ingredient_unit.name
      unless ingredient_unit_name
        Rails.logger.debug ingredient_unit
      end

      if @stock_ingredient_ids.include?(portion.ingredient_id)
        @portions_hash[portion.ingredient.name].store "in_cupboard", true
        matching_stocks = Stock.where(cupboard_id: @user_cupboard_ids, ingredient_id: portion.ingredient_id)
        stock_amount = 0

        matching_stocks.each do |stock|
          stock_amount += stock.quantity.comparable_amount
        end

        if ingredient_unit.metric_ratio
          stock_amount = stock_amount / ingredient_unit.metric_ratio
          portion_amount = portion_amount / ingredient_unit.metric_ratio
        end

        @portions_hash[portion.ingredient.name].store "stock_amount", stock_amount
        if stock_amount >= portion_amount
          @portions_hash[portion.ingredient.name].store "enough_in_cupboard", true
          if stock_amount > (portion_amount*1.5)
            @portions_hash[portion.ingredient.name].store "plenty_in_cupboard", true
          end
        end
        @portions_hash[portion.ingredient.name].store "percent_in_cupboard", ((stock_amount.to_f / portion_amount.to_f) * 100)
      else
        @portions_hash[portion.ingredient.name].store "in_cupboard", false
      end

      @portions_hash[portion.ingredient.name].store "portion_amount", portion_amount

      @portions_hash[portion.ingredient.name].store "unit_name", ingredient_unit_name
    end

    Rails.logger.debug @portions_hash




    # @not_in_stock = Portion.where(recipe_id: @, ingredient_id: @not_in_stock_ingredient_ids).uniq

  end

  def edit
		@shopping_list = ShoppingList.find(params[:id])
		@recipes = @shopping_list.recipes
	end
	def update
    @shopping_list = ShoppingList.find(params[:id])
    @shopping_list_portions = @shopping_list.shopping_list_portions
    @recipes = @shopping_list.recipes
    @existing_recipe_ids = []
    @recipes.each do |recipe|
      @existing_recipe_ids << recipe.id
    end

    @form_recipe_ids = params[:shopping_list][:recipes][:id]

    @recipes_to_remove = @existing_recipe_ids - @form_recipe_ids
    @recipes_to_add = @form_recipe_ids - @existing_recipe_ids

    @recipe_unpick = Recipe.find(@recipes_to_remove)
    @recipe_pick = Recipe.find(@recipes_to_add)

    @recipes.delete(@recipe_unpick)
    @recipes << @recipe_pick

    @recipes_to_remove.each do |recipe_id|
      @shopping_list_portions_to_delete = @shopping_list_portions.where(recipe_number: recipe_id)
      @shopping_list_portions.delete(@shopping_list_portions_to_delete)
    end

    shopping_list_portion_ids = []
    @recipe_pick.each do |recipe|
      recipe.portions.each do |portion|
        shopping_list_portion_ids.push(portion.id)
      end
    end

    shopping_list_portion_ids.each do |portion_id|
      portion_obj = Portion.where(id: portion_id).first
      ingredient_obj = Ingredient.where(id: portion_obj.ingredient_id).first
      if ingredient_obj
        @shopping_list.ingredients << ingredient_obj
        shopping_list_portion_obj = ShoppingListPortion.where(ingredient_id: ingredient_obj.id, shopping_list_id: @shopping_list.id)
        portion_unit_obj = Unit.where(id: portion_obj.unit_number).first

        shopping_list_portion_obj.each do |shopping_list_portion|
          view_context.metric_transform_portion_update(shopping_list_portion, portion_unit_obj, portion_obj, ingredient_obj)
        end
      end
    end

    if @shopping_list.update(shopping_list_params)
      redirect_to shopping_list_path(@shopping_list)
    else
      render 'edit'
    end
  end

  def delete
    @shopping_list = ShoppingList.find(params[:id])
    if current_user == @shopping_list.user
        @shopping_list.shopping_list_portions.destroy_all
        @shopping_list.shopping_list_recipes.destroy_all
        @shopping_list.destroy
        if current_user.shopping_lists.first
          redirect_to shopping_lists_path
        else
          redirect_to recipes_path
        end
    end
  end


  private
    def shopping_list_params
      params.require(:shopping_list).permit(:id, :date_created, recipes_attributes:[:id, :title, :description, :_destroy], shopping_list_portion_attributes:[:id, :unit_number, :_destroy], unit_attributes:[:id, :unit_type, :_destroy])
    end

    def user_has_shopping_lists
			unless current_user.shopping_lists.first
				redirect_to shopping_lists_new_path
			end
		end

    # Confirms a logged-in user.
		def logged_in_user
			unless logged_in?
				store_location
				flash[:danger] = "Please log in."
				redirect_to search_recipe_path
			end
    end
    def correct_user
      @shopping_list = ShoppingList.find(params[:id])
      unless current_user == @shopping_list.user
        store_location
        flash[:danger] = "That's not your shopping list!"
        redirect_to shopping_lists_path
      end
    end
end
