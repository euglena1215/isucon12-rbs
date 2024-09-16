# rbs_inline: enabled

require 'sqlite3'
require 'time'
require 'json'

module Isuports
  module SQLite3TraceLog
    class << self
      # @rbs self.@trace_file: File?

      # @rbs!
      #   def self.open: (String) -> void

      # @rbs skip
      def open(path)
        @trace_file = File.open(path, 'a', 0600)
      end

      # @rbs!
      #   def self.opened?: () -> bool

      # @rbs skip
      def opened?
        !@trace_file.nil?
      end

      # @rbs!
      #   def self.write: (Hash[Symbol, untyped]) -> void

      # @rbs skip
      def write(log)
        trace_file = @trace_file
        if trace_file
          trace_file.puts(JSON.dump(log))
        end
      end
    end
  end

  class SQLite3DatabaseWithTrace < SQLite3::Database #[SQLite3::result_as_hash]
    def execute(sql, bind_vars = [], *args, &block)
      unless SQLite3TraceLog.opened?
        return super
      end

      start = Time.now
      result =
        begin
          super
        rescue => e
        end
      finish = Time.now
      query_time = finish - start

      affected_rows =
        if result
          self.changes
        end
      affected_rows ||= 0
      log = {
        time: start.iso8601,
        statement: sql,
        args: bind_vars,
        query_time:,
        affected_rows:,
      }
      SQLite3TraceLog.write(log)
      # ここで e は宣言されてないのでは？よく分からない...
      result
    end
  end
end
