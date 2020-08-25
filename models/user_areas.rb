class UserAreas < ApplicationRecord

  belongs_to :user
  belongs_to :area


  after_create :add_user_to_basic_chat_room

  class << self

    def change(user_id, area_id, reset_approve = false)
      transaction do
        last_area = UserAreas.includes(user:[:sessions]).find_by(user_id: user_id, active: true)
        last_area&.update_attributes! active: false

        user = User.includes(:sessions).find(user_id)
        if reset_approve
          user.update_columns(location_approved_by_admin: false)
        end

        active_area = UserAreas.find_or_initialize_by(user: user,  area_id: area_id)
        active_area.active = true
        active_area.activated_at = Time.current
        active_area.save!


        if last_area.present?
          Area.unsubscribed_user_in_topic user, Area.topic(last_area.area_id)
        end

        Area.subscribed_user_in_topic user, Area.topic(active_area.area_id)

        user.update_attributes!(requested_area_id: nil)
      end
    end

  end


  private

  def add_user_to_basic_chat_room
    user_chat_room = area.basic_chat_room.user_chat_rooms.find_or_initialize_by(user_id: user_id)
    user_chat_room.user_chat_room_status = UserChatRoom.user_chat_room_statuses[:in_chat]
    user_chat_room.save!
  end

end
