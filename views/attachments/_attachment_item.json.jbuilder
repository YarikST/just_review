json.id attachment.id

json.entity_type attachment.entity_type
json.entity_id attachment.entity_id

json.file do
  json.url paperclip_url(attachment.file)
  json.name attachment.file_file_name
  json.content_type attachment.file_content_type
  json.size attachment.file_file_size
  json.correlation attachment.correlation ? attachment.correlation.to_f : nil
  json.preview do
    json.url paperclip_url(attachment.file, :thumb)
    json.content_type "image/png"
    json.correlation attachment.preview_correlation ? attachment.preview_correlation.to_f : nil
  end
  json.duration attachment.duration
end

json.created_at attachment.created_at.to_s

