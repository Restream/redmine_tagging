module TaggingPlugin
  module TagsHelper
    class << self
      def from_string(tags_string)
        tags_string.split(/[#"'\s,\\]+/) \
          .select { |tag| tag.length > 0 } \
          .map { |tag| "##{tag}" } \
          .join(', ')
      end

      def to_string(tags)
        tags.sort_by { |t| t.downcase }.map{ |tag| tag.gsub(/^#/, '') }.join(' ')
      end
    end
  end
end
