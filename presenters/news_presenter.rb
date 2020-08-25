class NewsPresenter

  attr_accessor :news

  delegate :news_id,
           :news_type,
           :title,
           :body,
           :target_portal,
           :effective_start_date,
           :effective_end_date,
           to: :news

  def initialize(news)
    @news = news
  end

  def portals
    @portals ||= Api::News.portals
  end

end