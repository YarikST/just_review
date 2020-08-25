class UserChatRoom < ApplicationRecord

  belongs_to :user
  belongs_to :invited_user, optional: true, class_name: 'User'
  belongs_to :chat_room
  has_many   :messages, ->(user_chat_room) {where(message_rooms:{owner_id: user_chat_room.user_id})}, through: :chat_room, source: :message_rooms


  enum user_chat_room_status: {
      in_chat: 1,
      out_chat: 2,
      blocked: 3,
  }


  validates :user_chat_room_status,
            presence: { message: {code: "E00247", message: "User chat room status must exist"}}


  validate  :user_chat_room_status_should_be_valid

  validate  :count_users

  after_commit  :run_notify_chat_add_user, on: :create, if: :run_notify_chat_add_user?

  after_save :unblocked_messages,
             if: :unblocked_messages?

  before_update :clear_history,
             if: :clear_history?


  def user_chat_room_status=(value)
    super value
    @user_chat_room_status_backup = nil
  rescue
    @user_chat_room_status_backup = value
    super nil
  end

  def clear_history
    self.first_read_message_id = last_read_message_id
  end

  private

  def clear_history?
    is_show_changed? && !is_show
  end

  def unblocked_messages?
    saved_change_to_user_chat_room_status? && user_chat_room_status_before_last_save == "blocked"
  end

  def unblocked_messages
    messages.where(is_block: true).update(is_block: false)
  end

  def run_notify_chat_add_user?
    chat_room.group_chat?
  end

  def run_notify_chat_add_user
    NotificationBroadcastJob.perform_async :chat_add_user, {user_id: user_id, room_id: chat_room_id}
  end

  def count_users
    if chat_room.direct_chat? && chat_room.count_in_chat_users > (new_record? ? 1 : 2)
      error_message = {code: "E00249", message: "There must be two users"}
      errors.add(:chat_room_type, error_message)
    elsif chat_room.group_chat?
    end
  end

  def user_chat_room_status_should_be_valid
    if @user_chat_room_status_backup.present?
      error_message = {code: "E00249", message: "#{@user_chat_room_status_backup} is not a valid user chat room status"}
      errors.add(:user_chat_room_status, error_message)
    end
  end

end
