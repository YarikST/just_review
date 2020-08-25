# frozen_string_literal: true

module WorkflowQueues
  module Programs
    module Actions
      class UnenrollSmokecessation < Actions::Base
        attr_reader :escalation_reason_cd

        def initialize(options = {})
          options.merge!(defaults)
          super
          @escalation_reason_cd = options[:escalation_reason_cd]
        end

        def call
          unenroll if unenroll?
        end

        private

        def unenroll?
          escalation_reason_cd == 'ESCALATIONRSN_TCUNENROLLMBR'
        end

        def unenroll
          make_program.unenroll(member: member)
        end

        def make_program
          program.new
        end

        def defaults
          {
            program_name: 'Program_Smokecessation'
          }
        end
      end
    end
  end
end
