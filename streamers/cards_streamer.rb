class CardsStreamer
  include Enumerable
  require 'csv'
  def initialize(dictionary_id)
    @dictionary_id = dictionary_id
  end
  def each
    query = Card.search_query({dictionary_id: @dictionary_id})
    offset = 0
    limit = 1000
    results = Card.find_by_sql(query.take(limit).skip(offset))
    while results.size > 0
      results = Card.find_by_sql(query.take(limit).skip(offset))
      offset += limit
      results.each do |card|
        yield CSV::Row.new([], [
            card.original_text,
            card.transcription,
            card.original_description,
            card.translated_text,
            card.translated_description || '' # fill last column if field is null
        ], true).to_csv(col_sep: ",", row_sep: "\r\n", quote_char: "\"")
      end
    end
  end
end