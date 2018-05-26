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
		if days_from_now.between?(2, -2)
			return ' date-part-warning'
		elsif days_from_now <= -2
			return ' date-full-warning'
		end
	end
	def stock_unit(stock)
		unit_number = stock.unit_number
		correct_unit = Unit.where(unit_number: unit_number).first
		return correct_unit.name
	end
	def cupboard_empty_class(cupboard)
		Rails.logger.debug 'stock number: ' + cupboard.stocks.where(hidden:false).length.to_s
		Rails.logger.debug 'cupboard id: ' + cupboard.id.to_s
		if cupboard.stocks.empty? || cupboard.stocks.where(hidden:false).length == 0
			return ' empty'
		else
			stocks = cupboard.stocks.order(use_by_date: :desc)
			days_from_now = (stocks.first.use_by_date - Date.current).to_i
			if days_from_now <= -2
				return ' all-out-of-date'
			end
		end
	end
end
