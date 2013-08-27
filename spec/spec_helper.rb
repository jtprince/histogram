require 'simplecov'
SimpleCov.start

require 'rspec'

require 'rspec/core/formatters/progress_formatter'
# doesn't say so much about pending guys
class QuietPendingFormatter < RSpec::Core::Formatters::ProgressFormatter
  def example_pending(example)
    output.print pending_color('*')
  end
end

require 'rspec/core/formatters/documentation_formatter'
class QuietPendingDocFormatter < RSpec::Core::Formatters::DocumentationFormatter
  def example_pending(example)
    output.puts pending_color( "<pending>: #{example.execution_result[:pending_message]}" )
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.formatter = QuietPendingDocFormatter
  config.color = true
end

TESTFILES = File.dirname(__FILE__) + "/testfiles"


