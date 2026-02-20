FactoryBot.define do
  factory :feature_flag do
    sequence(:name) { |n| "feature_#{n}" }
    global_default_state { false }
    description { "A feature flag" }

    trait :enabled do
      global_default_state { true }
    end

    trait :disabled do
      global_default_state { false }
    end
  end
end
