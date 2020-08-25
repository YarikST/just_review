# frozen_string_literal: true

module Consultations
  class Base < PresenterBase
    attr_reader :specialty, :specialty_key

    def initialize(params = {})
      @specialty = params[:specialty]

      init_specialty_key
    end

    def recommendation_text
      I18n.t("messages.followups.internal_referral_recommendation.#{specialty_key}")
    end

    private

    def init_specialty_key
      @specialty_key = specialty.parameterize.underscore
    end
  end

  def self.consultation(class_name)
    Consultations.const_get class_name
  rescue NameError
  end
end
