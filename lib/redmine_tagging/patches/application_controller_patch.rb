require_dependency 'application_controller'

module RedmineTagging::Patches::ApplicationControllerPatch
  extend ActiveSupport::Concern

  included do
    before_filter :include_tagging_helper
    before_filter :patch_queries_helper
  end

  # A way to make plugin helpers available in all views
  def include_tagging_helper
    unless _helpers.included_modules.include? TaggingHelper
      self.class.helper TaggingHelper
    end
    true
  end

  def patch_queries_helper
    if _helpers.included_modules.include?(QueriesHelper) &&
        !_helpers.included_modules.include?(RedmineTagging::Patches::QueriesHelperPatch)
      _helpers.send :include, RedmineTagging::Patches::QueriesHelperPatch
    end
    true
  end
end

unless ApplicationController.included_modules.include? RedmineTagging::Patches::ApplicationControllerPatch
  ApplicationController.send :include, RedmineTagging::Patches::ApplicationControllerPatch
end
