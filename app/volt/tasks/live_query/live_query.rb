require_relative 'query_tracker'

# Tracks a channel and a query on a collection.  Alerts
# the listener when the data in the query changes.
class LiveQuery
  attr_reader :current_ids, :collection, :query

  def initialize(pool, data_store, collection, query)
    @pool = pool
    @collection = collection
    @query = query

    @channels = []
    @data_store = data_store

    @query_tracker = QueryTracker.new(self, @data_store)

    run
  end

  def run(skip_channel=nil)
    @query_tracker.run(skip_channel)
  end

  def notify_removed(ids, skip_channel)
    notify! do |channel|
      # puts "Removed: #{ids.inspect} to #{channel.inspect}"
      channel.send_message("removed", nil, @collection, @query, ids)
    end
  end

  def notify_added(index, data, skip_channel)
    notify!(skip_channel) do |channel|
      # puts "Added: #{index} - #{data.inspect} to #{channel.inspect}"
      channel.send_message("added", nil, @collection, @query, index, data)
    end
  end

  def notify_moved(id, new_position, skip_channel)
    notify! do |channel|
      # puts "Moved: #{id}, #{new_position} to #{channel.inspect}"
      channel.send_message("moved", nil, @collection, @query, id, new_position)
    end
  end

  def notify_changed(id, data, skip_channel)
    notify!(skip_channel) do |channel|
      # puts "Changed: #{id}, #{data} to #{channel.inspect}"
      channel.send_message("changed", nil, @collection, @query, id, data)
    end
  end


  # return the query results the first time a channel connects
  def initial_data
    @query_tracker.results.map.with_index {|data, index| [index, data] }
  end

  def add_channel(channel)
    @channels << channel
  end

  def remove_channel(channel)
    @channels.delete(channel)

    if @channels.size == 0
      # remove this query, no one is listening anymore
      @pool.remove(@collection, @query)
    end
  end

  def notify!(skip_channel=nil, only_channel=nil)
    if only_channel
      channels = [only_channel]
    else
      channels = @channels
    end

    channels = channels.reject {|c| c == skip_channel }

    channels.each do |channel|
      yield(channel)
    end
  end

end
