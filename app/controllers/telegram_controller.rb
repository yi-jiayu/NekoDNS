class TelegramController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login
  wrap_parameters format: []
  before_action :set_command_and_args
  attr_reader :command, :args

  # In production, respond with success to Telegram webhooks
  # even if an error occurs so that Telegram does not continuously
  # retry the request, and manually report it to Sentry.
  rescue_from StandardError do |e|
    Raven.capture_exception(e)
    head :no_content
  end if Rails.env.production?

  def create
    return unless current_user

    @chat_id = chat_id
    case command
    when 'listzones'
      continue_in :list_zones
    when 'listrecords'
      continue_in :list_records
    when 'setrecord'
      continue_in :set_record
    end
  end

  def list_zones
    @zones = current_user.zones
    if @zones.empty?
      flash.alert = "You haven't created any zones yet! Head over to #{zones_url} to create one!"
      return render :flash
    end
  end

  def list_records
    root = args.split.first
    if root.nil?
      flash.alert = "Please specify a zone to list records for.
Usage: `/listrecords zone_root`
Example: `/listrecords example.com`"
      return render :flash
    end
    @zone = current_user.zones.find_by(root: root)
    if @zone.nil?
      flash.alert = "You don't have a zone with root `#{root}`!"
      return render :flash
    end
  end

  def set_record
    params = args.split
    if params.length < 5
      flash.alert = %q(Usage: /setrecord zone type name value TTL
Example: `/setrecord example.com A subdomain.example.com 93.184.216.34 300`)
      return render :flash
    end
    root, type, name, value, ttl = params
    @zone = current_user.zones.find_by(root: root)
    unless @zone
      flash.alert = 'Zone not found!'
      return render :flash
    end
    @record = Record.new(type: type, name: name, value: value, ttl: ttl.to_i)
    SetRecord.call(@zone, @record)
  rescue SetRecord::RecordInvalid => e
    flash.alert = "The record you specified was invalid! Reason: #{e.cause}"
    return render :flash
  end

  private

  def continue_in(action)
    self.action_name = action
    send(action)
  end

  def update_params
    params.permit(:update_id, message: [:text, { from: [:id, :first_name], chat: :id }])
  end

  def message_text
    update_params.dig(:message, :text)
  end

  def telegram_user_id
    update_params.dig(:message, :from, :id)&.to_i
  end

  def chat_id
    update_params.dig(:message, :chat, :id)&.to_i
  end

  def set_command_and_args
    match = /\/(\w+)@?\w* ?(.*)/.match(message_text)
    return if match.nil?

    @command = match[1]
    @args = match[2]
  end

  def current_user
    @current_user ||= User.find_by(telegram_user_id: telegram_user_id)
  end

  def set_raven_context
    super
    Raven.user_context(id: current_user&.id, telegram_user_id: telegram_user_id)
    Raven.tags_context(telegram_update_id: update_params[:update_id], telegram_chat_id: chat_id)
  end
end
