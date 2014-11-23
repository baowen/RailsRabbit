
require "bunny"
require "thread"

class RabbitClient

  attr_reader :reply_queue
  attr_accessor :response, :call_id
  attr_reader :lock, :condition

  def initialize(ch, server_queue)
    @ch = ch    
    @x = ch.default_exchange
    @server_queue = server_queue
    @reply_queue = ch.queue("", :exclusive => true)

    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self

    @reply_queue.subscribe do |delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response =payload.to_s
        that.lock.synchronize{that.condition.signal}
      end
    end

  end

  def call(message)
    self.call_id = self.generate_uuid

    @x.publish(message.to_s,
      :routing_key    => @server_queue,
      :correlation_id => call_id,
      :reply_to       => @reply_queue.name)

    lock.synchronize{condition.wait(lock)}
    response
  end

  protected

  def generate_uuid
    # very naive but good enough for code
    # examples
    "#{rand}#{rand}#{rand}"
  end

end

class RabbitServer

  def initialize(ch)
    @ch = ch
  end

  def start(queue_name)
    @q = @ch.queue(queue_name)
    @x = @ch.default_exchange

    @q.subscribe(:block => true) do |delivery_info, properties, payload|
      s = payload.to_s
#      r = self.class.reverser(s)
      puts " [.] server message  #{s.to_s}"
      @x.publish(s.reverse, :routing_key => properties.reply_to, :correlation_id => properties.correlation_id)
    end
  end

  def self.reverser(s)
    s
  end

end

