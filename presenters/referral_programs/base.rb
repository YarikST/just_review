# frozen_string_literal: true

module ReferralPrograms
  class Base < PresenterBase
    attr_reader :answer_cd, :answer_cd_key

    def initialize(params = {})
      @answer_cd = params[:answer_cd]

      init_answer_cd_key
    end

    def recommendation_text
      I18n.t("messages.followups.partner_referral_recommendation.#{answer_cd_key}")
    end

    private

    def init_answer_cd_key
      @answer_cd_key = answer_cd.split('_').last.downcase
    end
  end

  def self.program(class_name)
    ReferralPrograms.const_get class_name
  rescue NameError
  end
end
