class DictionaryStreamer

  def initialize(dictionary)
    @dictionary = dictionary
  end

  def each(&block)
    @dictionary.export_zip(&block)
  end
end