require 'net/smtp'
require 'mail'

# Email tools for MCP

# Helper methods for email tools
module EmailHelpers
  # Load SMTP configuration from environment variables
  # @param overrides [Hash] Optional overrides (e.g., {from: 'custom@example.com'})
  # @return [Hash] SMTP configuration hash
  def self.load_smtp_config(overrides = {})
    {
      host: ENV['SMTP_HOST'],
      port: ENV.fetch('SMTP_PORT', '587').to_i,
      user: ENV['SMTP_USER'],
      password: ENV['SMTP_PASSWORD'],
      from: overrides[:from] || ENV['SMTP_FROM'] || ENV['SMTP_USER'],
      tls: ENV.fetch('SMTP_TLS', 'true') == 'true'
    }
  end

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
    # Get SMTP configuration from environment
    config = EmailHelpers.load_smtp_config(from: params['from'])

    # Validate from address first (more specific error)
    unless config[:from]
      next "Error: No sender address specified. Set SMTP_FROM or provide 'from' parameter."
    end

    # Validate general SMTP configuration
    unless config[:host] && config[:user] && config[:password]
      next "Error: SMTP configuration missing. Please set SMTP_HOST, SMTP_USER, and SMTP_PASSWORD environment variables."
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
    config = EmailHelpers.load_smtp_config

    # Check configuration
    missing = []
    missing << 'SMTP_HOST' unless config[:host]
    missing << 'SMTP_USER' unless config[:user]
    missing << 'SMTP_PASSWORD' unless config[:password]

    unless missing.empty?
      next "Error: Missing SMTP configuration: #{missing.join(', ')}"
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
    config = EmailHelpers.load_smtp_config

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
