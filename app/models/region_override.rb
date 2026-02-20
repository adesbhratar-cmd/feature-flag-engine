class RegionOverride < ApplicationRecord
  # Associations
  belongs_to :feature_flag

  # Validations
  validates :region, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :region, uniqueness: { scope: :feature_flag_id, case_sensitive: false }

  # Scopes
  scope :for_region, ->(region) { where(region: region) }
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # Normalize region to lowercase for consistency
  before_save :normalize_region

  private

  def normalize_region
    self.region = region&.downcase&.strip
  end
end
