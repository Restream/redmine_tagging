module TaggingPlugin
  module ApiTemplateHandlerPatch
    class << self
      def included(base)
        base.send(:extend, ClassMethods)
        base.class_eval do
          class << self
            alias_method_chain :call, :api_replacement
          end
        end
      end
    end

    module ClassMethods
      def call_with_api_replacement(template)
        template = replace_if(template, /views\/issues\/index.api.rsb$/, 'app/views/issues/index_with_tags.api.rsb')
        template = replace_if(template, /views\/issues\/show.api.rsb$/, 'app/views/issues/show_with_tags.api.rsb')
        call_without_api_replacement(template)
      end

      def replace_if(template, regexp, new_path)
        if template.identifier =~ regexp
          new_template_filename = File.join(__dir__, '../..', new_path)
          source = File.open(new_template_filename).read
          identifier = template.identifier
          handler = template.handler
          template = ActionView::Template.new(source, identifier, handler, {})
        end
        template
      end
    end
  end
end

Redmine::Views::ApiTemplateHandler.send(:include, TaggingPlugin::ApiTemplateHandlerPatch)
