require "csv"

module SalesforceChunker
  module CSVIncremental

    CHUNK_SIZE = 50

    def parse(raw_csv_string)
      return to_enum(:parse, raw_csv_string) unless block_given?

      lines = raw_csv_string.each_line
      headers = CSV.parse_line(lines.next) # will this work if there is a newline?
      continue = true

      loop do
        stream = ""

        begin
          CHUNK_SIZE.times { stream += lines.next }
        rescue StopIteration
          continue = false
        end

        stream.gsub!("\"\"", "")

        begin
          csv = CSV.parse(stream)
        rescue CSV::MalformedCSVError
          nextline = lines.next
          stream += nextline.gsub!("\"\"", "")
          retry
        end

        csv.each do |record|
          yield(headers.zip(record).to_h)
        end

        break unless continue
      end
    end

    def blah_with_backoff(stream, lines)
        begin
          csv = CSV.parse(stream)
        rescue CSV::MalformedCSVError
          nextline = lines.next
          stream += nextline.gsub!("\"\"", "")
          retry
        end

    end
  end
end
