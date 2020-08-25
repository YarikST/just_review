class Api::V1::Chat::MessagesController < Api::V1::BaseController

  load_and_authorize_resource :room, class: ChatRoom
  before_action :load_user_chat_room, only: [:index, :create]
  load_and_authorize_resource class: MessageRoom, :through => :room, through_association: :message_rooms

  after_action :read_messages, only: :index
  after_action :update_last_read_message, only: :index
  after_action :read_chat_notifications, only: :index
  after_action :show_chat, only: :create

  def index
    page = resource_params[:page].to_i
    page = 1 if page < 1
    per_page = resource_params[:per_page].to_i
    per_page = 10 if per_page < 1

    query = MessageRoom.search_query resource_params
    count_query = MessageRoom.search_query resource_params.merge(count: true)

    @message_rooms = MessageRoom.find_by_sql(query.take(per_page).skip((page - 1) * per_page).to_sql)
    @count =  MessageRoom.find_by_sql(count_query.to_sql).first.count

    render json: {count: @count, timestamp: Time.current.to_f, message_rooms: @message_rooms.map(&:to_json)}
  end

  def show
    render json:{message: @message.to_json}
  end

  def create
    if @message.save
      render json:{message: @message.to_json}
    else
      render json: {errors: @message.errors.map{|k, v| v}}, status: :bad_request
    end
  end

  def update
    if @message.update_attributes update_params
      render json:{message: @message.to_json}
    else
      render json: {errors: @message.errors.map{|k, v| v}}, status: :bad_request
    end
  end

  def destroy
    if @message.update_attributes destroy_params
      render json: {message: 'Message has been successfully deleted.'}
    else
      render json: {errors: @message.errors.map{|k, v| v}}, status: :bad_request
    end
  end

  private

  def resource_params
    allowed_params = params.permit :room_id, :timestamp, :page, :per_page

    allowed_params[:current_user] = current_user

    allowed_params
  end

  def create_params
    allowed_params = params.permit :uuid, :text, :attachment_id, :message_type, :shared_id

    allowed_params[:message_status] = :created
    allowed_params[:is_block] = @user_chat_room.blocked?
    allowed_params[:owner] = current_user

    allowed_params
  end

  def update_params
    allowed_params = params.permit :text, :attachment_id, :message_type, :shared_id

    allowed_params[:message_status] = :updated

    if params[:attachment_id_nil].present?
      if MessageRoom
             .where(message_type: MessageRoom.message_types[:forward], shared_id: @message.id).count > 0
        allowed_params[:attachment_id] = nil
      else
        allowed_params[:attachment] = nil
      end
    end

    allowed_params
  end

  def destroy_params
    {
        message_status: :deleted,
    }
  end

  def update_last_read_message
    if @message_rooms.first.present?
      last_read_message_id =  @message_rooms.first.id

      @user_chat_room.update_attributes last_read_message_id: last_read_message_id if (@user_chat_room.last_read_message_id || 0) < last_read_message_id
    end
  end

  def read_messages
    no_read_messages = @message_rooms.reject(&:read)

    last_read_message_id = @room.last_read_message_id

    prepare_for_reading = no_read_messages.select{|message| message.id <= last_read_message_id}

    prepare_for_reading.each {|message| message.update_attributes read: true}
  end

  def read_chat_notifications
    @room.read_chat_notification current_user
  end

  def show_chat
    if @room.direct_chat? && !@user_chat_room.in_chat?
      @user_chat_room.update_attributes!(is_show: true)
    else
      @room.in_chat_users.where(is_show: false).update(is_show: true)
    end
  end

  def load_user_chat_room
    @user_chat_room = @room.interlocutor current_user.id
  end

end