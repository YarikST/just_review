module Ccr
  class List

    attr_reader :member_id
    attr_reader :items

    def initialize(member_id)
      @member_id = member_id
      @items = []
    end

    def dropdown_items
      build_consultation_items
      build_default_items
      items
    end

    private

    def consultations
      @consultations ||= Consultation.joins(:group_service_specialty_relation)
                                     .completed.where(member_id: member_id)
                                     .group(:service_specialty_cd)
                                     .order(:consultation_id)
                                     .sort_by(&:specialty_name)
    end

    def build_consultation_items
      consultation_items = consultations.map do |co|
        [
            co.specialty_name,
            co.consultation_id,
            create_data(co.consultation_id, 'Consultation')
        ]
      end

      items.concat consultation_items
    end

    def build_default_items
      items.unshift(['All Health Records', '', create_data(member_id, 'Member' )])
    end

    def create_data actor_id, actor_type
      {data: {actor_id: actor_id, actor_type: actor_type }}
    end
  end
end
