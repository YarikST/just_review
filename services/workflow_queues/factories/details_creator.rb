# frozen_string_literal: true

module WorkflowQueues
  module Factories
    module DetailsCreator
      def details_creator
        default_details_creator
      end

      private

      def default_details_creator
        WorkflowQueues::DetailsCreator.new(
          workflow_queue: workflow_queue,
          completing_person: completing_person
        )
      end
    end
  end
end
