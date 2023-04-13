# frozen_string_literal: true

require "logger"
require "irb"

require "openai"

module IRB
  module OpenAI
    class Completion

      DEFAULT_PROMPT = <<~'EOM'
        Generate the continuation code up to the end of the line of the Ruby program given in the Input section. Do not include input codes. The choices to be generated should be in the form "- ...\n- ...\n".
        ## Input
      EOM

      def initialize
        @client = ::OpenAI::Client.new(api_key: IRB::OpenAI.api_key, default_engine: "text-davinci-003")
        file = File.open("irb.log", "a")
        file.sync = true
        @logger = Logger.new(file)
      end

      def call(target, preposing = nil, postposing = nil)
        normal_completions = IRB::InputCompletor::CompletionProc.call(target, preposing, postposing)
        input = "#{preposing}#{target}"
        prompt = DEFAULT_PROMPT + input
        res = @client.completions(prompt: prompt)
        completions = res.choices.first.text.scan(/^- (.+)$/).flatten.map{|completion|
          completion.start_with?(target) ? completion : target + completion
        }
        @logger.debug(prompt)
        @logger.debug(res.choices.first.text)
        @logger.debug("completions: #{completions}")
        completions + normal_completions
      end

      def proc
        @proc ||= lambda do |target, preposing = nil, postposing = nil|
          call(target, preposing, postposing)
        end
      end
    end
  end
end
