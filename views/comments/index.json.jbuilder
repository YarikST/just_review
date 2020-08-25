created_user = User.new

json.comments @comments do |comment|
  json.id comment.id

  json.payload comment.payload
  json.fixed comment.fixed

  created_user.attributes = comment['created_user'].except("rating")
  json.created_user do
    json.id created_user.id

    json.name created_user.name
    json.avatar paperclip_url(created_user.avatar)
    json.supervisor created_user.supervisor
    json.position created_user.position
    json.rating comment['created_user']["rating"]
    json.phone_number comment['created_user']['phone_number']
    json.admin created_user.role_id == Role.employer.id
  end

  json.observation_type comment.observation_type
  json.observation_id comment.observation_id

  json.replay_count comment.replay_count
  json.replay_name comment.replay_name

  json.created_at comment.created_at.to_s
end
json.count @count
json.timestamp Time.current.to_f