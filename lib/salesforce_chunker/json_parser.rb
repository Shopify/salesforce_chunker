require 'oj'

module SalesforceChunker
  class JsonParser
    def hash_start
      {}
    end

    def hash_set(h,k,v)
      h[k] = v
    end

    def array_start
      []
    end

    def array_append(a, value)
      @block.call(value)
      a
    end

    def error(message, line, column)
      # raise?
      p "ERROR: #{message}"
    end

    def parse(json_string, &block)
      @block = block
      Oj.sc_parse(self, json_string)
      nil
    end
  end
end
