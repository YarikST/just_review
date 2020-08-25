json.attachments @attachments do |attachment|
  json.valid attachment.valid?

  if attachment.valid?
    json.partial! '/api/v1/attachments/attachment_item', attachment: attachment
  else
    json.errors attachment.errors.map{|k,v| v}
  end
end