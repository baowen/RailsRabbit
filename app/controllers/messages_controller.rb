require "bunny"
require "rabbitmixin"

class MessagesController < ApplicationController

  before_action :set_message, only: [:show, :edit, :update, :destroy]

  # GET /messages
  # GET /messages.json
  def index
    @messages = Message.all
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create

    @message = Message.new(message_params)

    conn = Bunny.new(:automatically_recover => false)
    conn.start
    ch = conn.create_channel

    client = RabbitClient.new(ch, "rpc_queue")
    response = client.call(@message.text).to_s
    @message.response = response.to_s
    puts " [.] Got #{response}"
#    q = ch.queue("message")
#    ch.default_exchange.publish(@message.text, :routing_key => q.name)
    ch.close
    conn.close

    respond_to do |format|
      if @message.save
        format.html { redirect_to @message, notice: 'Message was successfully sent and received.' }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to @message, notice: 'Message was successfully updated.' }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    
    respond_to do |format|

    if @message.destroy
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    else 
       format.html { redirect_to messages_url, notice: 'Message was NOT successfully destroyed.' }
    end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:text)
    end
end
