# frozen_string_literal: true

module WorkflowQueues
  class DetailsCreator
    attr_reader :workflow_queue, :completing_person

    def initialize(options = {})
      @workflow_queue               = options[:workflow_queue]
      @completing_person            = options[:completing_person]
    end

    def create(complete = false)
      domain_user = person
      desc = description
      desc += update_description_for_detail if complete
      WorkflowQueueDetail.new_item(workflow_queue, desc, domain_user.try(:id), completing_person.try(:person_type)) # allows nil user for updates from console
    end

    private

    def description
      "changed state to #{workflow_queue.status}"
    end

    def person
      completing_person.person_type.constantize.find(completing_person.person_type_id) if completing_person # allows nil user for updates from console, for assign/unassign/revoke
    end

    def update_description_for_detail
      workflow_queue.actor.is_a?(NurseAction) ? update_description_for_nurse_action : ''
    end

    def update_description_for_nurse_action
      return update_description_for_video_consult if workflow_queue.actor.consultation.is_video?
      return '; Questions asked for the followup' if workflow_queue.actor.is_program?

      ''
    end

    def update_description_for_video_consult
      if workflow_queue.actor.consultation.state_machine_cd == 'CONSULTSTATUS_COM'
        "; SCHEDULED FOR: #{workflow_queue.actor.consultation.scheduled_dt} (Central Time) DOCTOR: #{Provider.find(workflow_queue.actor.consultation.provider_id).person.full_nm}"
      else
        '; consultation was not completed'
      end
    end
  end
end
