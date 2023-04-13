# frozen_string_literal: true

require "json"
require "irb"
require "irb/completion"

require_relative "openai/version"
require_relative "openai/completion"

CONFIG_PATH = File.join(Dir.home, ".config", "irb", "openai.json")

module IRB
  module OpenAI
    class Error < StandardError; end

    module Loader
      def run(conf = IRB.conf)
        ::IRB::OpenAI.load!
        super(conf)
      end
    end

    class << self
      def load!
        if ENV["OPENAI_API_KEY"]
          IRB::OpenAI.api_key = ENV["OPENAI_API_KEY"]
        elsif File.exist?(CONFIG_PATH)
          config = JSON.parse(File.read(File.expand_path(CONFIG_PATH)))
          IRB::OpenAI.api_key = config["api_key"]
        end
        completion = IRB::OpenAI::Completion.new
        Reline.completion_proc = completion.proc
      end

      def api_key=(api_key)
        @api_key = api_key
      end

      def api_key
        @api_key
      end
    end
  end
end

IRB::Irb.prepend(IRB::OpenAI::Loader)
