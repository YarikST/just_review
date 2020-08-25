# frozen_string_literal: true

module WorkflowQueues
  module Programs
    module Actions
      class Base
        attr_reader :member, :program_name

        def initialize(options = {})
          @member                       = options[:member]
          @program_name                 = options[:program_name]
        end

        def call
          raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
        end

        private

        def program
          Program.const_get(program_name.split('_').last.downcase.camelize)
        end
      end
    end
  end
end
