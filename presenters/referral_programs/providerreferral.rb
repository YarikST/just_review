# frozen_string_literal: true

module ReferralPrograms
  class Providerreferral < Base
    def recommendation_url
      url_helpers.information_provider_referral_path
    end
  end
end
