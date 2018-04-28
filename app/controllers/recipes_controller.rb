class RecipesController < ApplicationController
	include ActionView::Helpers::UrlHelper

	before_action :logged_in_user, only: [:index, :edit]
	before_action :user_has_recipes, only: :index
	before_action :admin_user,     only: [:create, :new, :edit, :update]

	def index
		@recipes = Recipe.paginate(:page => params[:page], :per_page => 20)
		@fallback_recipes = Recipe.all.sample(4)
		@your_recipes_length = current_user.favourites.length
		@your_recipes_sample = current_user.favourites.first(4)
	end
	def search
		if params[:search]
			@recipes = Recipe.search(params[:search]).order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
		else
			@recipes = Recipe.all.order('created_at DESC')
		end
		@fallback_recipes = Recipe.all.sample(4)
	end
	def show
		@recipe = Recipe.find(params[:id])
		@portions = @recipe.portions
		@ingredients = @recipe.ingredients
	end
	def favourites
		@your_recipes = current_user.favourites.paginate(:page => params[:page], :per_page => 5)
	end
	def new
		@recipe = Recipe.new
  end
  def create
    @recipe = Recipe.new(recipe_params)
    if @recipe.save
      redirect_to '/recipes'
    else
      render 'new'
    end
	end
	def edit
		@recipe = Recipe.find(params[:id])
		@portions = @recipe.portions
	end
	def update
		@recipe = Recipe.find(params[:id])
		@portions = @recipe.portions
      if @recipe.update(recipe_params)
        redirect_to recipe_path(@recipe)
      else
        render 'edit'
      end
	end
	# Add and remove favourite recipes
  # for current_user
  def favourite
		type = params[:type]
		@recipe = Recipe.find(params[:id])
		recipe_title = @recipe.title
    if type == "favourite"
			current_user.favourites << @recipe
			@string = "Added the \"#{link_to(@recipe.title, recipe_path(@recipe))}\" recipe to favourites"
      redirect_back fallback_location: root_path, notice: @string

    elsif type == "unfavourite"
			current_user.favourites.delete(@recipe)
			@string = "Removed the \"#{link_to(@recipe.title, recipe_path(@recipe))}\" recipe from favourites"
			redirect_back fallback_location: root_path, notice: @string

    else
      # Type missing, nothing happens
      redirect_back fallback_location: root_path, notice: 'Nothing happened.'
    end
	end
	def add_to_shopping_list
		@recipe = Recipe.find(params[:id])
		recipe_title = @recipe.title

		# if at least one shopping list exists
		if current_user.shopping_lists.length

			# add recipe to the last edited(?) shopping list
			last_shopping_list = current_user.shopping_lists.order('created_at DESC').first
			last_shopping_list.recipes << @recipe
			@recipe.ingredients.each do |ingredient|
				last_shopping_list.ingredients << ingredient
			end

			# find index of shopping list
			userShoppingLists = current_user.shopping_lists
			zero_base_index = userShoppingLists.index(last_shopping_list)
			shopping_list_index = zero_base_index + 1
			shopping_list_ref = "#" + shopping_list_index.to_s + " " + last_shopping_list.created_at.to_date.to_s(:long)

			# give notice that the recipe has been added with link to shopping list
			@string = "Added the #{@recipe.title} to shopping list from #{link_to(shopping_list_ref, shopping_list_path(last_shopping_list))}"
			redirect_back fallback_location: root_path, notice: @string

		# if no shopping lists exist
		else
			# create a new shopping list
			@shopping_list = ShoppingList.new(shopping_list_params)
			current_user.shopping_lists << @shopping_list

			# add the recipe to that shopping list
			@shopping_list.recipes << @recipe
			@recipe.ingredients.each do |ingredient|
				@shopping_list.ingredients << ingredient
			end

			# find index of shopping list
			userShoppingLists = current_user.shopping_lists
			zero_base_index = userShoppingLists.index(@shopping_list)
			shopping_list_index = zero_base_index + 1
			shopping_list_ref = "#" + shopping_list_index.to_s + " " + @shopping_list.created_at.to_date.to_s(:long)

			# give notice that the recipe has been added with link to shopping list
			@string = "Added the #{@recipe.title} to shopping list #{link_to(shopping_list_ref, shopping_list_path(@shopping_list))}"
			redirect_back fallback_location: root_path, notice: @string
		end
	end

	private
		def recipe_params
			params.require(:recipe).permit(:user_id, :search, :title, :description, portions_attributes:[:id, :amount, :_destroy], ingredients_attributes:[:id, :name, :image, :unit, :_destroy])
		end

		def shopping_list_params
      params.require(:shopping_list).permit(:id, :date_created, recipes_attributes:[:id, :title, :description, :_destroy])
    end

		# Confirms a logged-in user.
		def logged_in_user
			unless logged_in?
				store_location
				flash[:danger] = "Please log in."
				redirect_to search_recipe_path
			end
		end

		def user_has_recipes
			unless current_user.favourites.first
				redirect_to search_recipe_path
			end
		end

		# Confirms an admin user.
		def admin_user
			redirect_to(root_url) unless current_user.admin?
		end
end
