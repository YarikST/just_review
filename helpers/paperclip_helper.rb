module PaperclipHelper

  def clear_orientation_exif paperclip_attachment, style
    path = path_in_attachment(paperclip_attachment, style)

    `convert #{path} -auto-orient #{path}`
  end

  def generate_correlation paperclip_attachment, style
    image = MiniMagick::Image.open(path_in_attachment(paperclip_attachment, style))
    image["%[fx:w/h]"] # "0.75"
  end

  def generate_video_time paperclip_attachment, style
    result = `ffmpeg -i #{path_in_attachment(paperclip_attachment, style)} -f null - 2>&1`
    r = result.match("Duration: (([0-9]+):([0-9]+):([0-9]+).([0-9]+))")

    if r.present?
      r[1]
    else
      raise "Duration parse invalid"
    end
  end

  def generate_frame_index paperclip_attachment, style
    generate_frame_index_in_path path_in_attachment(paperclip_attachment, style)
  end

  def generate_frame_index_in_path path
    result = `ffmpeg -i #{path} -f null - 2>&1`
    r = result.match("frame= ([0-9]+)")

    if r.present?
      r[1].to_i
    else
      raise "Frame index parse invalid"
    end
  end

  def path_in_attachment paperclip_attachment, style
    paperclip_attachment.staged_path(style) || paperclip_attachment.path(style)
  end

  def arel_fields table, paperclip_attachment_name
    [
        table["#{paperclip_attachment_name}_file_name"],
        table["#{paperclip_attachment_name}_content_type"],
        table["#{paperclip_attachment_name}_file_size"],
        table["#{paperclip_attachment_name}_updated_at"]
    ]
  end

  def import_s3 relation, paperclip_attachment
    system_setting = SystemSetting.instance
    config_s3 system_setting


    bucket = setting_bucket system_setting

    options = {
        acl: "public-read"
    }

    relation.each do|record|
      p "Record #{record.id}", '*'*100

      attachment = record.send(paperclip_attachment)
      styles = attachment.styles.keys + [:original]
      relation_name = record.class.name.pluralize.downcase
      attachment_file_name = record.send("#{paperclip_attachment}_file_name")

      styles.each do|style|
        p "Style #{style}", '-'*10


        load_path = block_given? ? yield(relation_name, style, record.id, attachment_file_name) : "#{Rails.root}/public/system/#{relation_name}/#{style}/#{record.id}/#{attachment_file_name}"

        p "System path(#{load_path}) present #{File.file?(load_path)} and s3 present #{attachment.exists?(style)}"
        next unless File.file?(load_path) && !attachment.exists?(style)

        save_path = "#{relation_name}/#{style}/#{record.id}/#{attachment_file_name}"

        p "Save #{save_path}"
        bucket.object(save_path).upload_file(load_path, options)
      end
      puts
    end
  end

  def export_s3 class_obj, paperclip_attachment
    system_setting = SystemSetting.instance
    config_s3 system_setting

    client = Aws::S3::Client.new

    options = {
        bucket: system_setting.storage_bucket,
        delimiter: nil,
        prefix: class_obj.name.pluralize.downcase,
        max_keys: 5,
        continuation_token: nil,
    }

    options[:prefix]= class_obj.name.pluralize.downcase + '/' + 'original' + '/'

    begin
      p 'Load'
      resp = client.list_objects_v2(options)
      objects = resp.contents

      objects.each do |obj|
        keys  = obj.key.split('/')
        p "Key #{obj.key}"

        begin
          exemplar = class_obj.find keys[2]

          exemplar.send("#{paperclip_attachment}=", client.get_object({
                                                                          bucket: options[:bucket],
                                                                          key: obj.key
                                                                      }).body)

          unless exemplar.save
            p "Errors #{exemplar.errors.full_messages}"
          end
        rescue ActiveRecord::RecordNotFound => found
          p "#{found.model} not found #{found.id}"
        end
      end

      options[:continuation_token] = resp.next_continuation_token
      puts
    end while resp.is_truncated
  end

  private

  def config_s3 system_setting
    Aws.config.update({
                          region: system_setting.storage_region,
                          endpoint: "https://#{system_setting.storage_host_name}",
                          credentials: Aws::Credentials.new(system_setting.storage_access_key_id, system_setting.storage_secret_access_key)
                      })
  end

  def setting_bucket system_setting
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(system_setting.storage_bucket)

    unless bucket.exists?
      p "Create bucket #{system_setting.storage_bucket}"
      bucket.create
    end

    bucket
  end

end