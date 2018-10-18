require "csv"

module SalesforceChunker
  module CSVIncremental

    CHUNK_SIZE = 50

    def parse(csv_string)
      return to_enum(:parse, csv_string) unless block_given?

      lines = csv_string.each_line
      headers = CSV.parse_line(lines.next)

      continue = true

      while continue
        chunk = ""

        begin
          CHUNK_SIZE.times { chunk += lines.next }
        rescue StopIteration
          continue = false
        end

        chunk.gsub!("\"\"", "")

        begin
          records = CSV.parse(chunk)
        rescue CSV::MalformedCSVError
          chunk += lines.next.gsub("\"\"", "")
          retry
        end

        records.each do |record|
          yield(headers.zip(record).to_h)
        end
      end
    end
  end
end
