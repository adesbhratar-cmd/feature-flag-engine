class GroupOverride < ApplicationRecord
  # Associations
  belongs_to :feature_flag

  # Validations
  validates :group_id, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :group_id, uniqueness: { scope: :feature_flag_id, case_sensitive: false }

  # Scopes
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # Normalize group_id to lowercase for consistency
  before_save :normalize_group_id

  private

  def normalize_group_id
    self.group_id = group_id&.downcase&.strip
  end
end
