require 'niceql'

module Sqlcomposer
  module Cli
    class << self
      def start
        prepared_sql = nil
        ARGF.each do |line|
          prepared_sql = parse_prepared_sql(line) if line =~ /=>\s+Preparing:/
          params = parse_params(prepared_sql, line) if line =~ /=>\s+Parameters:/
          if prepared_sql && params
            sql = compose_sql(prepared_sql, params)
            if $stdout.isatty
              puts format_sql(sql, true)
            else
              puts format_sql(sql, false)
            end
            puts "\n\n"
            prepared_sql = nil
          end
        end
      end

      def parse_prepared_sql(line)
        line.split(/=>\s+Preparing:/).last.chomp
      end

      def parse_params(raw_sql, line)
        return [] unless raw_sql
        raw_params = line.split(/=>\s+Parameters:/).last.chomp.strip
        raw_params.split(/,\s*/).map do |raw_param|
          raw_param.strip.scan(/([^()]+)\((\w+?)\)/).first
        end
      end

      def compose_sql(raw_sql, params)
        return raw_sql if params.nil? || params.empty?
        sql = raw_sql.dup
        sql.scan(/\?/).each_with_index do |place_holder, idx|
          sql.sub!(/\?/) do |_|
            quote_param(params[idx])
          end
        end
        sql
      end

      def quote_param(param)
        value, type = param
        if %w[Integer Byte BigDecimal].include?(type)
          value
        else
          "'#{value}'"
        end
      end

      def format_sql(sql, color)
        Niceql::Prettifier.prettify_sql(sql + ';', color)
      end
    end
  end
end
