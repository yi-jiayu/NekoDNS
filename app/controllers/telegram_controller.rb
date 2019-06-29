class TelegramController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login
  wrap_parameters format: []
  before_action :set_command_and_args
  attr_reader :command, :args

  def create
    return continue_in :link_telegram_account if command == 'start'
    return unless current_user

    @chat_id = chat_id
    case command
    when 'listdomains'
      continue_in :list_domains
    when 'listrecords'
      continue_in :list_records
    when 'setrecord'
      continue_in :set_record
    end
  end

  def link_telegram_account
    TelegramService.instance.link_telegram_account(args, telegram_user_id)
  end

  def list_domains
    @domains = current_user.domains
  end

  def list_records
    root = args.split.first
    @domain = Domain.find_by(root: root, user: current_user)
  end

  def set_record
    params = args.split
    if params.length < 5
      flash.alert = %q(Usage: /setrecord domain type name value TTL
Example: `/setrecord example.com A subdomain.example.com 93.184.216.34 300`)
      return render :flash
    end
    root, type, name, value, ttl = params
    @domain = Domain.find_by(root: root, user: current_user)
    unless @domain
      flash.alert = 'Domain not found!'
      return render :flash
    end
    @record = Record.new(type: type, name: name, value: value, ttl: ttl.to_i)
    DomainService.instance.set_record(@domain, @record)
  rescue DomainService::Errors::RecordInvalid
    flash.alert = 'The record you specified was invalid!'
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
end
