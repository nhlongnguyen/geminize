# Rails Chat Example

This is a basic example of how to implement a chat application with the Geminize gem in a Rails application.

## Features

- Chat interface with Google's Gemini AI
- Conversation memory between requests using Rails session
- Support for Turbo and JSON responses
- Reset conversation functionality

## Implementation

This example demonstrates:

1. How to include Geminize controller concerns
2. How to use Geminize view helpers
3. How to maintain conversation state in a Rails application

## File Structure

- `app/controllers/chat_controller.rb` - Controller with Geminize integration
- `app/views/chat/index.html.erb` - Chat interface view
- `config/routes.rb` - Routes configuration

## Setup in Your Application

1. Add Geminize to your Gemfile:

```ruby
gem 'geminize'
```

2. Run the installer:

```bash
rails generate geminize:install
```

3. Configure your API key in `config/initializers/geminize.rb`

4. Include the Geminize helpers in your `ApplicationHelper`

```ruby
module ApplicationHelper
  geminize_helper
end
```

5. Create your controller with Geminize support

```ruby
class YourChatController < ApplicationController
  geminize_controller

  # ... your controller actions
end
```

6. Use the helper methods in your views

```erb
<%= render_gemini_conversation %>
<%= gemini_chat_form %>
```

## Styling

This example includes basic CSS to style the chat interface. Feel free to customize it to match your application's design.
