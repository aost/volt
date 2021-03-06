require_relative 'live_query'
require 'volt/utils/generic_pool'

class LiveQueryPool < GenericPool
  def initialize(data_store)
    super()
    @data_store = data_store
  end

  def lookup(collection, query)
    query = normalize_query(query)

    return super(collection, query)
  end

  def updated_collection(collection, skip_channel)
    lookup_all(collection).each do |live_query|
      # puts "RUN ON: #{live_query} with #{live_query.instance_variable_get('@channels').inspect}"
      live_query.run(skip_channel)
    end
  end

  private
    # Creates the live query if it doesn't exist, and stores it so it
    # can be found later.
    def create(collection, query)
      # If not already setup, create a new one for this collection/query
      return LiveQuery.new(self, @data_store, collection, query)
    end

    def normalize_query(query)
      # TODO: add something to sort query properties so the queries are
      # always compared the same.
      return query
    end
end
