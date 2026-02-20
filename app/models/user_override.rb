class UserOverride < ApplicationRecord
  # Associations
  belongs_to :feature_flag

  # Validations
  validates :user_id, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: :feature_flag_id, case_sensitive: false }

  # Scopes
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # Normalize user_id to lowercase for consistency
  before_save :normalize_user_id

  private

  def normalize_user_id
    self.user_id = user_id&.downcase&.strip
  end
end
