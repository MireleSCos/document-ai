module DocumentAi
  class NamesMatch
    def self.call(first_name, second_name)
      normalize(first_name) == normalize(second_name)
    end

    def self.normalize(value)
      value.to_s
        .unicode_normalize(:nfkd)
        .encode("ASCII", replace: "")
        .downcase
        .gsub(/[^a-z\s]/, "")
        .squeeze(" ")
        .strip
    end

    private_class_method :normalize
  end
end
