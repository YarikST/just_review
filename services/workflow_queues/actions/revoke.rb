# frozen_string_literal: true

module WorkflowQueues
  module Actions
    class Revoke < Actions::Base
      include Factories::DetailsCreator

      def call
        WorkflowQueue.transaction do
          update_attributes
          details_creator.create
        end
      end

      private

      def update_attributes
        workflow_queue.update_attributes!(pending_til: nil, owner: nil)
      end
    end
  end
end
