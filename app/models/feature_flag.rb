class FeatureFlag < ApplicationRecord
  # Associations
  has_many :user_overrides, dependent: :destroy
  has_many :group_overrides, dependent: :destroy
  has_many :region_overrides, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :global_default_state, inclusion: { in: [true, false] }

  # Scopes
  scope :enabled_by_default, -> { where(global_default_state: true) }
  scope :disabled_by_default, -> { where(global_default_state: false) }

  # Normalize name to lowercase for consistency
  before_save :normalize_name

  private

  def normalize_name
    self.name = name&.downcase&.strip
  end
end
