require "embulk/parser/query_string"

module Embulk
  module Guess
    # $ embulk guess -g "query_string" partial-config.yml

    class QueryString < LineGuessPlugin
      Plugin.register_guess("query_string", self)

      def guess_lines(config, sample_lines)
        return {} unless config.fetch("parser", {}).fetch("type", "query_string") == "query_string"

        parser_config = config.param("parser", :hash)
        options = {
          strip_quote: parser_config.param("strip_quote", :bool, default: true),
          strip_whitespace: parser_config.param("strip_whitespace", :bool, default: true),
          capture: parser_config.param("capture", :string, default: nil)
        }
        records = sample_lines.map do |line|
          Parser::QueryString.parse(line, options) || {}
        end
        format = records.inject({}) do |result, record|
          record.each_pair do |key, value|
            (result[key] ||= []) << value
          end
          result
        end
        guessed = {type: "query_string", columns: []}
        format.each_pair do |key, values|
          if values.any? {|value| value.match(/[^0-9]/) }
            guessed[:columns] << {name: key, type: :string}
          else
            guessed[:columns] << {name: key, type: :long}
          end
        end
        return {"parser" => guessed}
      end
    end

  end
end
