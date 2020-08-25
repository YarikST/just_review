# frozen_string_literal: true

module ReferralPrograms
  class Chroniccarecoaching < Base
    attr_reader :program

    def initialize(params = {})
      # TODO: we need to get selected program
      @program = params[:program]

      super
    end

    def recommendation_url
      url_helpers.information_vida_path
    end

    private
    # TODO: we need to use a program as part of the key for translation text
    def init_answer_cd_key
      super

      # @answer_cd_key = "#{answer_cd_key}_#{program.parameterize.underscore}"
    end
  end
end
