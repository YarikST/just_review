# frozen_string_literal: true

module ReferralPrograms
  class Physicaltherapy < Base
    def recommendation_url
      url_helpers.information_telespine_physical_therapy_path
    end
  end
end
