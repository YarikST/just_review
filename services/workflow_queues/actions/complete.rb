# frozen_string_literal: true

module WorkflowQueues
  module Actions
    class Complete < Actions::Base
      attr_reader :escalation_reason_cd, :grievance_category_cd, :case_summary_resolution, :case_origination_cd, :lab_note

      def initialize(options = {})
        super
        @escalation_reason_cd         = options[:escalation_reason_cd]
        @grievance_category_cd        = options[:grievance_category_cd]
        @case_summary_resolution      = options[:case_summary_resolution]
        @case_origination_cd          = options[:case_origination_cd]
        @lab_note                     = options[:lab_note]
      end

      def call
        WorkflowQueue.transaction(requires_new: true) do
          completer
          complete_children
          complete_request_for_excuse_note
          set_grievance_category_cd
          set_case_summary_resolution
          set_case_origination_cd
          set_pending_and_owner
          set_escalation_reason
          workflow_queue.save!
          unenroll_member_from_smokecessation_program
        end
      end

      private

      def unenroll_member_from_smokecessation_program
        WorkflowQueues::Programs::Actions::UnenrollSmokecessation.new(
          member: workflow_queue.actor.communicator,
          escalation_reason_cd: escalation_reason_cd
        ).call
      end

      def set_escalation_reason
        workflow_queue.assign_attributes(escalation_reason_cd: escalation_reason_cd)
      end

      def set_pending_and_owner
        workflow_queue.assign_attributes(pending_til: nil, owner: nil)
      end

      def set_case_origination_cd?
        case_origination_cd.present?
      end

      def set_case_origination_cd
        workflow_queue.assign_attributes(case_origination_cd: case_origination_cd) if set_case_origination_cd?
      end

      def set_case_summary_resolution?
        case_summary_resolution.nil?
      end

      def set_case_summary_resolution
        workflow_queue.assign_attributes(case_summary_resolution: case_summary_resolution) unless set_case_summary_resolution?
      end

      def set_grievance_category_cd?
        grievance_category_cd.present?
      end

      def set_grievance_category_cd
        workflow_queue.assign_attributes(grievance_category_cd: grievance_category_cd) if set_grievance_category_cd?
      end

      def complete_request_for_excuse_note?
        workflow_queue.actor.is_a?(NurseAction) && workflow_queue.actor.nurse_action_cd.eql?('NURSEACTION_EXCUSENOTE')
      end

      def complete_request_for_excuse_note
        NurseAction.complete_request_for_excuse_note(workflow_queue.actor, completing_person) if complete_request_for_excuse_note?
      end

      def children
        workflow_queue.children
      end

      def complete_children
        children.each do |item|
          complete_item item
        end
      end

      def complete_item_params
        {
          completing_person: completing_person
        }
      end

      def complete_item(item)
        item.complete(complete_item_params)
      end

      def completer_options
        {
          workflow_queue_id: workflow_queue.id,
          caller_id: completing_person.id,
          caller_type: completing_person.class.name,
          options: { lab_note: lab_note }
        }
      end

      def completer
        WorkflowQueueCompleterWorker.perform_async(completer_options)
      end
    end
  end
end
