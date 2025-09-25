#!/bin/env ruby

class PBSimply
  class ConfigChecker
    class InvalidConfigError < StandardError
    end

    def self.verify_config config
      # blessmethod_accs_rel
      if config["blessmethod_accs_rel"] && ! %w:numbering date timestamp lexical:.include?(config["blessmethod_accs_rel"])
        raise InvalidConfigError.new("blessmethod_accs_rel must be either numbering, date, timestamp or lexical.")
      end

      # unicode_normalize
      if config["unicode_normalize"] && ! %w:nfc nfd nfkc nfkd:.include?(config["unicode_normalize"])
        raise InvalidConfigError.new("unicode_normalize must be either nfc, nfd, nfkc or nfkd.")
      end
    end
  end
end
