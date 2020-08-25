module FindInQueryBatches
  extend ActiveSupport::Concern

  module ClassMethods
    def find_in_query_batches(query,  options)
      options[:batch_size] ||= 1000

      query.orders.clear

      records_query = query.
          order(arel_attribute(primary_key).asc).
          take(options[:batch_size])

      unless options[:finish].nil?
        records_query = records_query.where(arel_attribute(primary_key).lteq(options[:finish]))
      end

      unless options[:start].nil?
        records_query = records_query.where(arel_attribute(primary_key).gteq(options[:start]))
      end

      last_id = nil

      loop do
        unless last_id.nil?
          records_query = records_query.where(arel_attribute(primary_key).gt(last_id))
        end

        records = self.find_by_sql(records_query)

        break if records.empty?

        yield records

        last_id = records.last.id

        break if records.length < options[:batch_size]
      end
    end

    def find_in_query_each(query,  options)
      self.find_in_query_batches(query, options) do |records|
        records.each { |record| yield record }
      end
    end
  end
end