# frozen_string_literal: true

module Consultations
  class BehavioralHealth < Base
    attr_reader :feature

    def initialize(params = {})
      @feature = params[:feature]

      super
    end

    private

    def init_specialty_key
      super

      internal_provider = internal_provider_skills(feature)
      return unless internal_provider.present?
      @specialty_key = "#{specialty_key}_#{internal_provider.parameterize.underscore}"
    end

    def internal_provider_skills(feature)
      TeladocConstants::Referral::INTERNAL_PROVIDER_SKILLS[feature]
    end
  end
end
