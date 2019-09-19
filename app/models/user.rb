class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token, :cupboard_id
  before_save   :downcase_email
  before_create :create_activation_digest
  before_destroy :destroy_associated_records
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
										format: { with: VALID_EMAIL_REGEX },
										uniqueness: { case_sensitive: false }
	has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  has_many :recipes

  has_many :cupboard_users
  has_many :cupboards, through: :cupboard_users

  has_many :shopping_lists, dependent: :destroy
  has_many :user_fav_stocks, dependent: :destroy
  has_many :user_recipe_stock_matches, dependent: :destroy
  has_one :user_setting, dependent: :destroy

	has_many :stock_users
  has_many :stocks, through: :stock_users

  # Favourite recipes of user
  has_many :favourite_recipes # just the 'relationships'
  has_many :favourites, through: :favourite_recipes, source: :recipe # the actual recipes a user favourites

  has_one :planner_shopping_list
  has_many :planner_recipes
  has_many :planner_shopping_list_portions
  has_many :combi_planner_shopping_list_portions

  class << self
    # Returns the hash digest of the given string.
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # Returns a random token.
    def new_token
      SecureRandom.urlsafe_base64
    end
  end

	# Remembers a user in the database for use in persistent sessions.
	def remember
		self.remember_token = User.new_token
		update_attribute(:remember_digest, User.digest(remember_token))
	end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

	# Forgets a user.
	def forget
		update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Sends activation email with cupboard add.
  def send_activation_email_with_cupboard_add
    UserMailer.account_activation_with_cupboard_sharing(self).deliver_now
  end

  def send_checking_email_with_scheduler(stock_going_off)
    UserMailer.ingredient_out_of_date_notification(self, stock_going_off).deliver_now
  end

  def feedback_email(user, issue_details, current_path)
    UserMailer.admin_feedback_notification(user, issue_details, current_path).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Sends shopping list to cupboard reminder.
  def send_shopping_list_reminder_email
    UserMailer.shopping_list_reminder(self).deliver_later(wait_until: 24.hours.from_now)
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private

    # Converts email to all lower-case.
    def downcase_email
      email.downcase!
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end

    def destroy_associated_records
      self.cupboard_users.destroy_all
      self.stock_users.destroy_all
      self.stock.destroy_all
    end
end
