json.comment do
  json.id @comment.id

  json.payload @comment.payload
  json.fixed @comment.fixed

  json.created_user do
    json.id current_user.id

    json.name current_user.name
    json.avatar paperclip_url(current_user.avatar)
    json.supervisor current_user.supervisor
    json.position current_user.position
    json.rating current_user.current_user_area.rating
    json.phone_number current_user.phone_number
  end

  json.observation_type @comment.observation_type
  json.observation_id @comment.observation_id

  json.replay_count 0
  json.replay_name @comment.replay_user&.name

  json.created_at @comment.created_at.to_s
end
json.timestamp Time.current.to_f