class FeedbackController < ApplicationController
	def submit
		if params.has_key?(:user_id) && params.has_key?(:user_email)
			user = {
				user_id: params[:user_id],
				user_email: params[:user_email]
			}
		else
			user = false
		end

		if params.has_key?(:issue_details)
			issue_details = params[:issue_details]
		else
			issue_details = false
		end

		if params.has_key?(:current_path)
			current_path = params[:current_path]
		else
			current_path = false
		end

		UserMailer.admin_feedback_notification(user, issue_details, current_path).deliver_now
		@string = "Thank you for the feedback!"
		redirect_back fallback_location: root_path, notice: @string
	end
end
