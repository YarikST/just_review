class Admin::CardsController < Admin::BaseController

  before_action :card_load, only: [:update, :show, :destroy, :activeted, :deactiveted]

  def index
    respond_to do |format|
      format.json do
        page = params[:page].to_i
        page = 1 if page < 1
        per_page = params[:per_page].to_i
        per_page = 10 if per_page < 1

        query = Card.search_query params

        count_query = query.clone.project('COUNT(*)')

        @cards = Card.find_by_sql(query.take(per_page).skip((page - 1) * per_page).to_sql)
        @count = Card.find_by_sql(count_query.to_sql).count
      end
      format.zip do
        dictionary = Dictionary.find(params[:dictionary_id])
        content_type = Mime::Type.lookup_by_extension('zip')

        headers["X-Accel-Buffering"] = "no"
        headers["Cache-Control"] = "no-cache"
        headers['Content-Disposition'] = "attachment; filename=\"#{dictionary.name.gsub '"', '\"'}.#{content_type.symbol}\""
        headers['Content-Type'] = content_type.to_s
        headers["Last-Modified"] = Time.zone.now.httpdate

        headers.delete("Content-Length")

        self.response_body = DictionaryStreamer.new(dictionary)
      end
    end
  end

  def create
    dictionary = Dictionary.find card_params[:created_dictionary_id]
    @card = dictionary.cards.build(card_params)

    if dictionary.save
      render json: { message: I18n.t('dictionary.messages.success_upsert') }
    else
      render json: { validation_errors: @card.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @card.update_attributes card_params
      render json: { message: I18n.t('card.messages.success_upsert') }
    else
      render json: { validation_errors: @card.errors }, status: :unprocessable_entity
    end
  end

  def show

  end

  def destroy
    if @card.destroy
      render json: { message: I18n.t('card.messages.destroy') }
    else
      render json: {errors: @card.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def activeted
    if @card.activeted
      render json: { message: I18n.t('card.messages.activeted') }
    else
      e = @card.errors.full_messages
      e = I18n.t(['card.messages.faild.activeted']) if e.blank?
      render json: {errors: e }, status: :unprocessable_entity
    end
  end

  def deactiveted
    if @card.deactiveted
      render json: { message: I18n.t('card.messages.deactiveted') }
    else
      render json: {errors: I18n.t(['card.messages.faild.deactiveted']) }, status: :unprocessable_entity
    end
  end

  # related models actions

  private

  def card_params
    params.require(:card).permit!
  end

  def card_load
    query = Card.search_query params
    @card = Card.find_by_sql(query.to_sql).first
  end

end
