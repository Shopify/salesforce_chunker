module SalesforceChunker
  module Base62

    BASE_DIGITS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

    def self.encode(decimal)
      return "" if decimal == 0
      return self.encode(decimal / 62) + BASE_DIGITS[decimal % 62]
    end

    def self.decode(base62)
      return 0 if base62 == ""
      return 62 * self.decode(base62.chop) + BASE_DIGITS.index(base62[-1])
    end
  end
end
