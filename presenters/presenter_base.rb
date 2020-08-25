class PresenterBase
  delegate :url_helpers, to: 'Rails.application.routes'
end
