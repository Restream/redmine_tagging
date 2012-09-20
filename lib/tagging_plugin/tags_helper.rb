module TaggingPlugin
  module TagsHelper
    class << self
      def from_string(tags_string)
        tags_string.split(/[#"'\s,]+/) \
          .collect { |tag| "##{tag}" } \
          .join(', ')
      end

      def to_string(tags)
        tags.sort.collect{|tag| tag.gsub(/^#/, '')}.join(' ')
      end
    end
  end
end
