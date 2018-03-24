class StocksController < ApplicationController
	before_action :logged_in_user
	# before_action :cupboard_id_param_check, only: [:create, :new, :edit, :update]
	def index
		@stocks = Stock.all
	end
	def show
		@stock = Stock.find(params[:id])
	end
	def edit
		@stock = Stock.find(params[:id])
		@cupboards = current_user.cupboards
		@current_cupboard = @stock.cupboard
		@ingredients = Ingredient.all.order('name ASC')
		@current_ingredient = @stock.ingredient
		@units = Unit.all
		@units_select_volume = Unit.where(:unit_type => 'volume')
		@units_select_mass = Unit.where(unit_type: "mass")
		@units_select_other = Unit.where(unit_type: "other")
		@current_ingredient_unit = @stock.ingredient.unit.unit_number
		@current_unit = @stock.unit_number

		if @current_ingredient.unit.unit_type == "volume"
			@units_select = @units_select_volume
		elsif @current_ingredient.unit.unit_type == "mass"
			@units_select = @units_select_mass
		else
			@units_select = @units_select_other
		end
	end
	def update
		@stock = Stock.find(params[:id])
		@cupboards = current_user.cupboards
		@current_cupboard = @stock.cupboard
		@ingredients = Ingredient.all.order('name ASC')
		@current_ingredient = @stock.ingredient
		@units_select_volume = Unit.where(:unit_type => 'volume')
		@units_select_mass = Unit.where(unit_type: "mass")
		@units_select_other = Unit.where(unit_type: "other")
		@current_ingredient_unit = @stock.ingredient.unit.unit_number
		@current_unit = @stock.unit_number

		if @current_ingredient.unit.unit_type == "volume"
			@units_select = @units_select_volume
		elsif @current_ingredient.unit.unit_type == "mass"
			@units_select = @units_select_mass
		else
			@units_select = @units_select_other
		end


		if not params[:cupboard_id] == @current_cupboard.id
			@stock.update_attributes(
				cupboard_id: params[:cupboard_id]
			)
			@current_cupboard = Cupboard.where(id: params[:cupboard_id]).first
		end

		if not params[:unit_number] == @current_unit
			@stock.update_attributes(
				unit_number: params[:unit_number]
			)
		end

		if @stock.update(stock_params)
			redirect_to cupboard_path(@current_cupboard)
		else
			render 'edit'
		end
	end
	def new
		@stock = Stock.new
		@cupboards = current_user.cupboards
		@ingredients = Ingredient.all.order('name ASC')
		@units = Unit.all
		@two_weeks_from_now = Date.current + 2.weeks
		@unit_select = []

		@units.each do |unit|
			if unit.unit_number == 5
				@unit_select << unit
			elsif unit.unit_number == 8
				@unit_select << unit
			elsif unit.unit_number == 11
				@unit_select << unit
			elsif unit.unit_number == 22
				@unit_select << unit
			elsif unit.unit_number == 25
				@unit_select << unit
			end
		end
	end
	def create
		@stock = Stock.new(stock_params)
		@cupboards = current_user.cupboards
		@ingredients = Ingredient.all.order('name ASC')
		@units = Unit.all
		@two_weeks_from_now = Date.current + 2.weeks
		@unit_select = []

		@units.each do |unit|
			if unit.unit_number == 5
				@unit_select << unit
			elsif unit.unit_number == 8
				@unit_select << unit
			elsif unit.unit_number == 11
				@unit_select << unit
			elsif unit.unit_number == 22
				@unit_select << unit
			elsif unit.unit_number == 25
				@unit_select << unit
			end
		end

		if params[:ingredient][:name].present?
			@selected_ingredient_name = params[:ingredient][:name]
			@selected_ingredient = Ingredient.where(name: @selected_ingredient_name).first
			@selected_ingredient_id = @selected_ingredient.id
		elsif params[:ingredient_id].present?
			@selected_ingredient_id = params[:ingredient_id]
		end

		if params[:cupboard_id].present?
			@selected_cupboard_id = params[:cupboard_id]
		elsif params[:cupboards].present?
			@selected_cupboard_id = params[:cupboards]
			if @selected_cupboard_id.length > 1
				@selected_cupboard_id = @selected_cupboard_id.join
			end
		else
			## falls back to adding stock to the first of the users cupboards if not selected
			@selected_cupboard_id = @cupboards.first
		end

		@stock_amount = params[:amount]
		@stock_use_by_date = params[:stock][:use_by_date]
		@stock_unit = params[:unit_number]


		@stock.update_attributes(
			unit_number: @stock_unit,
			cupboard_id: @selected_cupboard_id,
			ingredient_id: @selected_ingredient_id
		)

		@cupboard_for_stock = @cupboards.where(id: @selected_cupboard_id).first

    if @stock.save
      redirect_to cupboard_path(@cupboard_for_stock)
    else
			render 'new'
			flash[:danger] = "Make sure you select an ingredient"
    end
	end
	private
		def stock_params
			params.require(:stock).permit(:amount, :use_by_date, :unit_number, ingredient_attributes: [:id, :name, :image, :unit, :_destroy])
		end

		# Confirms a logged-in user.
		def logged_in_user
			unless logged_in?
				store_location
				flash[:danger] = "Please log in."
				redirect_to login_url
			end
		end

		def cupboard_id_param_check
			unless params.has_key?(:cupboard_id)
				redirect_to cupboards_path
				flash[:danger] = "Add stock by editing a cupboards contents"
			end
		end
end