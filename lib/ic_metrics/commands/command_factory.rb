# frozen_string_literal: true

module IcMetrics
  module Commands
    # Factory to create command objects
    class CommandFactory
      COMMANDS = {
        'collect' => CollectCommand,
        'analyze' => AnalyzeCommand,
        'report' => ReportCommand,
        'export' => ExportCommand,
        'export-advanced' => ExportAdvancedCommand,
        'analyze-csv' => AnalyzeCsvCommand,
        'help' => HelpCommand
      }.freeze

      def self.create(name, config, args)
        command_class = COMMANDS[name] || HelpCommand
        command_class.new(config, args)
      end
    end
  end
end
