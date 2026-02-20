FactoryBot.define do
  factory :group_override do
    association :feature_flag
    sequence(:group_id) { |n| "group_#{n}" }
    enabled { false }

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
