module TaggingPlugin
  module ContextHelper
    class << self
      def context_for(project)
        "context_" + project.identifier.gsub('-', '_')
      end
    end
  end
end
