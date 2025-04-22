# frozen_string_literal: true

module GeminizeHelper
  # Render the Gemini conversation as HTML
  # @param conversation [Geminize::Models::Conversation, nil] Conversation to render (defaults to current_gemini_conversation)
  # @param options [Hash] Optional rendering options
  # @option options [String] :user_class CSS class for user messages
  # @option options [String] :ai_class CSS class for AI messages
  # @option options [Boolean] :include_timestamps Include message timestamps
  # @return [String] HTML representation of the conversation
  def render_gemini_conversation(conversation = nil, options = {})
    conversation ||= current_gemini_conversation if respond_to?(:current_gemini_conversation)
    return content_tag(:div, "No conversation available", class: "gemini-empty-conversation") unless conversation

    content_tag(:div, class: "gemini-conversation") do
      conversation.messages.map do |message|
        render_gemini_message(message, options)
      end.join.html_safe
    end
  end

  # Render a single message from the conversation
  # @param message [Geminize::Models::Message] The message to render
  # @param options [Hash] Optional rendering options
  # @return [String] HTML representation of the message
  def render_gemini_message(message, options = {})
    is_user = message.role == "user"

    message_class = if is_user
      options[:user_class] || "gemini-user-message"
    else
      options[:ai_class] || "gemini-ai-message"
    end

    content_tag(:div, class: "gemini-message #{message_class}") do
      output = []

      # Add the role label
      output << content_tag(:div, is_user ? "You" : "AI", class: "gemini-message-role")

      # Add the message content (convert newlines to <br> tags)
      output << content_tag(:div, simple_format(message.parts.first["text"]), class: "gemini-message-content")

      # Add timestamp if requested
      if options[:include_timestamps] && message.respond_to?(:timestamp) && message.timestamp
        timestamp = message.timestamp.is_a?(Time) ? message.timestamp : Time.parse(message.timestamp.to_s)
        output << content_tag(:div, timestamp.strftime("%Y-%m-%d %H:%M:%S"), class: "gemini-message-timestamp")
      end

      output.join.html_safe
    end
  end

  # Create a chat form that handles submitting messages to Gemini
  # @param options [Hash] Form options
  # @option options [String] :submit_text Text for the submit button (default: "Send")
  # @option options [String] :placeholder Placeholder text (default: "Type your message...")
  # @option options [String] :form_class CSS class for the form
  # @option options [String] :input_class CSS class for the input field
  # @option options [String] :submit_class CSS class for the submit button
  # @option options [String] :url URL to submit the form to (default: current URL)
  # @return [String] HTML form
  def gemini_chat_form(options = {})
    default_options = {
      submit_text: "Send",
      placeholder: "Type your message...",
      form_class: "gemini-chat-form",
      input_class: "gemini-chat-input",
      submit_class: "gemini-chat-submit",
      url: request.path
    }

    opts = default_options.merge(options)

    form_tag(opts[:url], method: :post, class: opts[:form_class]) do
      output = []
      output << text_area_tag(:message, nil, placeholder: opts[:placeholder], class: opts[:input_class])
      output << submit_tag(opts[:submit_text], class: opts[:submit_class])
      output.join.html_safe
    end
  end

  # Render Markdown text as HTML
  # @param text [String] Markdown text to render
  # @param options [Hash] Options for rendering
  # @return [String] HTML content
  def markdown_to_html(text, options = {})
    return "" if text.blank?

    # Check if the markdown gem is available
    if defined?(Redcarpet)
      renderer = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: false)
      markdown = Redcarpet::Markdown.new(renderer, options)
      markdown.render(text).html_safe
    else
      # Fall back to simple formatting if Redcarpet is not available
      simple_format(text)
    end
  end

  # Add syntax highlighting to code blocks
  # @param html [String] HTML content that may contain code blocks
  # @return [String] HTML with syntax highlighting applied
  def highlight_code(html)
    return html unless defined?(Rouge)

    formatter = Rouge::Formatters::HTML.new

    # Find all code blocks and apply syntax highlighting
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("pre code").each do |code|
      lang = code["class"]&.sub("language-", "") || "text"
      lexer = Rouge::Lexer.find(lang) || Rouge::Lexers::PlainText.new

      # Get the code content and format it
      code_text = code.text
      highlighted = formatter.format(lexer.lex(code_text))

      # Replace the original code block with the highlighted version
      code.parent.replace("<pre class=\"highlight #{lang}\">#{highlighted}</pre>")
    end

    doc.to_html.html_safe
  end
end
