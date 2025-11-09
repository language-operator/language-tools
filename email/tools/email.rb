require 'net/smtp'
require 'mail'
require 'language_operator'

# Email tools for MCP

# Helper methods for email tools
module EmailHelpers
  # Parse comma-separated email addresses
  # @param addresses_str [String, nil] Comma-separated email addresses
  # @return [Array<String>] Array of trimmed email addresses
  def self.parse_email_addresses(addresses_str)
    addresses_str ? addresses_str.split(',').map(&:strip) : []
  end
end

tool "send_email" do
  description "Send an email via SMTP"

  parameter "to" do
    type :string
    required true
    description "Recipient email address (comma-separated for multiple recipients)"
  end

  parameter "subject" do
    type :string
    required true
    description "Email subject line"
  end

  parameter "body" do
    type :string
    required true
    description "Email body content (plain text or HTML)"
  end

  parameter "from" do
    type :string
    required false
    description "Sender email address (defaults to SMTP_FROM env variable)"
  end

  parameter "cc" do
    type :string
    required false
    description "CC email addresses (comma-separated)"
  end

  parameter "bcc" do
    type :string
    required false
    description "BCC email addresses (comma-separated)"
  end

  parameter "html" do
    type :boolean
    description "Send as HTML email (default: false)"
    default false
  end

  execute do |params|
    # Get SMTP configuration from environment using SDK
    begin
      config = LanguageOperator::Config.load(
        { host: 'HOST', port: 'PORT', user: 'USER', password: 'PASSWORD', from: 'FROM', tls: 'TLS' },
        prefix: 'SMTP',
        required: [:host, :user, :password],
        defaults: { port: '587', tls: 'true', from: ENV['SMTP_USER'] },
        types: { port: :integer, tls: :boolean }
      )

      # Override from if provided in params
      config[:from] = params['from'] if params['from']

      # Validate from address
      unless config[:from]
        next LanguageOperator::Errors.missing_config("sender address (SMTP_FROM or 'from' parameter)")
      end
    rescue RuntimeError => e
      next e.message
    end

    # Parse recipients
    to_addresses = EmailHelpers.parse_email_addresses(params['to'])
    cc_addresses = EmailHelpers.parse_email_addresses(params['cc'])
    bcc_addresses = EmailHelpers.parse_email_addresses(params['bcc'])

    # Build the email using the mail gem
    mail = Mail.new do
      from     config[:from]
      to       to_addresses
      cc       cc_addresses unless cc_addresses.empty?
      bcc      bcc_addresses unless bcc_addresses.empty?
      subject  params['subject']

      if params['html']
        content_type 'text/html; charset=UTF-8'
        body params['body']
      else
        text_part do
          body params['body']
        end
      end
    end

    begin
      # Send via SMTP
      if config[:tls]
        # Use STARTTLS
        Net::SMTP.start(config[:host], config[:port], 'localhost', config[:user], config[:password], :login) do |smtp|
          smtp.send_message(mail.to_s, config[:from], to_addresses + cc_addresses + bcc_addresses)
        end
      else
        # Plain SMTP
        Net::SMTP.start(config[:host], config[:port], 'localhost', config[:user], config[:password]) do |smtp|
          smtp.send_message(mail.to_s, config[:from], to_addresses + cc_addresses + bcc_addresses)
        end
      end

      "Email sent successfully to #{to_addresses.join(', ')}"
    rescue StandardError => e
      "Error sending email: #{e.message}"
    end
  end
end

tool "test_smtp" do
  description "Test SMTP connection and configuration"

  execute do |params|
    # Load SMTP configuration using SDK
    begin
      config = LanguageOperator::Config.load(
        { host: 'HOST', port: 'PORT', user: 'USER', password: 'PASSWORD', from: 'FROM', tls: 'TLS' },
        prefix: 'SMTP',
        required: [:host, :user, :password],
        defaults: { port: '587', tls: 'true', from: ENV['SMTP_USER'] },
        types: { port: :integer, tls: :boolean }
      )
    rescue RuntimeError => e
      next e.message
    end

    # Test connection
    begin
      Net::SMTP.start(config[:host], config[:port], 'localhost', config[:user], config[:password], :login) do |smtp|
        # Connection successful
      end

      <<~RESULT
        SMTP Configuration Test: SUCCESS

        Host: #{config[:host]}
        Port: #{config[:port]}
        User: #{config[:user]}
        From: #{config[:from]}
        TLS: #{config[:tls]}

        Connection to SMTP server successful!
      RESULT
    rescue StandardError => e
      <<~RESULT
        SMTP Configuration Test: FAILED

        Host: #{config[:host]}
        Port: #{config[:port]}
        User: #{config[:user]}

        Error: #{e.message}
      RESULT
    end
  end
end

tool "email_config" do
  description "Display current email configuration (without sensitive data)"

  execute do |params|
    # Load SMTP configuration using SDK (no validation required for display)
    config = LanguageOperator::Config.from_env(
      { host: 'HOST', port: 'PORT', user: 'USER', password: 'PASSWORD', from: 'FROM', tls: 'TLS' },
      prefix: 'SMTP',
      defaults: { port: '587', tls: 'true', from: ENV['SMTP_USER'] },
      types: { port: :integer, tls: :boolean }
    )

    password_set = config[:password] ? 'Yes (hidden)' : 'No'

    <<~CONFIG
      Email Configuration:

      SMTP_HOST: #{config[:host] || '(not set)'}
      SMTP_PORT: #{config[:port]}
      SMTP_USER: #{config[:user] || '(not set)'}
      SMTP_FROM: #{config[:from] || '(not set)'}
      SMTP_TLS: #{config[:tls]}
      SMTP_PASSWORD: #{password_set}

      Note: Set these via environment variables when running the container.
    CONFIG
  end
end
