# frozen_string_literal: true

module WorkflowQueues
  class Completer
    attr_reader :workflow_queue, :completing_person, :lab_note

    include Factories::DetailsCreator

    def initialize(options = {})
      @workflow_queue               = options[:workflow_queue]
      @completing_person            = options[:completing_person]
      @lab_note                     = options[:lab_note]
    end

    def call
      WorkflowQueue.transaction do
        details_creator.create(true)
        create_messages
        notify_subject_of_completion
        update_customer_service_action_index
        unenroll_member_from_smokecessation_program
        complete_member_from_smokecessation_program
      end
    end

    private

    def unenroll_member_from_smokecessation_program
      Program::Smokecessation.new.unenroll(member: workflow_queue.actor.communicator) if escalation_reason_cd == 'ESCALATIONRSN_TCUNENROLLMBR'
    end

    def complete_member_from_smokecessation_program
      Program::Smokecessation.new.complete(workflow_queue) if escalation_reason_cd == 'ESCALATIONRSN_TCFOLLOWUPCOM'
    end

    def create_messages
      if workflow_queue.actor.is_a?(NurseAction) && workflow_queue.actor.action_cd.eql?('NURSEACTION_VCON')
        member = workflow_queue.actor.consultation.member
        Notifications::Email.video_confirmation_notification(workflow_queue.actor.consultation, member.group.group_setting)
      end

      if workflow_queue.actor.actor.is_a?(ProviderInteraction) && lab_note.present?
        provider_interaction = workflow_queue.actor.actor
        reviewer = completing_person.is_a?(Person) ? completing_person.get_domain_object : completing_person
        message = lab_note
        provider_interaction.review!(reviewer, message)
      end
    end

    def notify_subject_of_completion
      workflow_queue.subject.completed_workflow_queue!(completing_person) if workflow_queue.subject.respond_to?(:completed_workflow_queue!)
    end

    def update_customer_service_action_index
      if workflow_queue.escalation_reason_cd.present? && workflow_queue.actor_type == 'CustomerServiceAction'
        csa = CustomerServiceAction.where(customer_service_action_id: workflow_queue.actor_id).first
        ElasticsearchIndexer.perform_in(15.seconds, :update, 'CustomerServiceAction', csa.customer_service_action_id) if csa.present?
      end
    end
  end
end
