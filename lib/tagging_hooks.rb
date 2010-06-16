module TaggingPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener
      def view_issues_sidebar_planning_bottom(context={ })
        return context[:controller].send(:render_to_string, {
            :partial => 'tagging/tagcloud',
            :locals => context
          })
      end

    end
  end
end
