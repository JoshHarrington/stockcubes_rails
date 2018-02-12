class IngredientsController < ApplicationController
	def index
		@ingredients = Ingredient.all
	end
	def show
		@ingredient = Ingredient.find(params[:id])
		@meals = @ingredient.meals
		@cupboards = @ingredient.cupboards
		@portions = @ingredient.portions
	end
	def new 
    @ingredient = Ingredient.new 
  end
  def create
    @ingredient = Ingredient.new(ingredient_params)
    if @ingredient.save
      redirect_to '/ingredients'
    else
      render 'new'
    end
	end
	private 
		def ingredient_params 
			params.require(:ingredient).permit(:name, :image) 
		end
end
