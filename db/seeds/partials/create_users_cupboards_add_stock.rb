admin_user = User.create(name:  "Admin User",
			email: ENV['PERSONAL_ADMIN_EMAIL'],
			password:              ENV['PERSONAL_PASSWORD'],
			password_confirmation: ENV['PERSONAL_PASSWORD'],
			admin: true,
			activated: true,
      activated_at: Time.zone.now)
      
standard_user = User.create(name:  "Standard User",
			email: ENV['PERSONAL_STANDARD_EMAIL'],
			password:              ENV['PERSONAL_PASSWORD'],
			password_confirmation: ENV['PERSONAL_PASSWORD'],
			activated: true,
			activated_at: Time.zone.now)

c1 = Cupboard.create(location: "Fridge Door")
c2 = Cupboard.create(location: "Fridge Bottom Drawer")
c3 = Cupboard.create(location: "Fridge Top Shelf")
c4 = Cupboard.create(location: "Cupboard by the Oven")

admin_user.cupboards << [c1, c3, c4]
standard_user.cupboards << c2

ingredient_picks = Ingredient.all.sample(15)

ingredient_picks.each_with_index do |ingredient, index|

  ingredient_obj = Ingredient.where(id: ingredient.id).first
  
  cupboard_pick = admin_user.cupboards.sample
  
  test_use_by_date = Date.today + 2.weeks + index.days

  stock = Stock.create(    
    amount: 0.1,
    use_by_date: test_use_by_date,
    unit_number: ingredient_obj.unit.unit_number,
    cupboard_id: cupboard_pick.id,
    ingredient_id: ingredient_obj.id
  )
  
end