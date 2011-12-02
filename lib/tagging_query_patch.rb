require_dependency 'query'

module TaggingPlugin
  module QueryPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      alias_method_chain :available_filters, :tags
      alias_method_chain :sql_for_field, :tags

      add_available_column(QueryColumn.new(:issue_tags, :caption => :tags))
    end

  end

  module InstanceMethods
    def available_filters_with_tags
      @available_filters = available_filters_without_tags

      if project.nil?
        tags = ActsAsTaggableOn::Tag.find(:all, :conditions => "id in (select tag_id from taggings where taggable_type = 'Issue')")
      else
        tags = ActsAsTaggableOn::Tag.find(:all,
                :conditions => ["id in (select tag_id from taggings where taggable_type = 'Issue' and context = ?)", project.identifier.gsub('-', '_')])
      end
      tags = tags.collect {|tag| [tag.name.gsub(/^#/, ''), tag.name]}

      tag_filter = {
        "tags" => {
          :type => :list_optional,
          :values => tags,
          :order => 20
        }
      }

      return @available_filters.merge(tag_filter)
    end

    def sql_for_field_with_tags(field, operator, v, db_table, db_field, is_custom_filter=false)
      if field == "tags"
        selected_values = values_for(field)

        sql = selected_values.collect{|val| "'#{ActiveRecord::Base.connection.quote_string(val.downcase.gsub('\'', ''))}'"}.join(',')
        sql = "(#{Issue.table_name}.id in (select taggable_id from taggings join tags on tags.id = taggings.tag_id where taggable_type='Issue' and tags.name in (#{sql})))"
        sql = "(not #{sql})" if operator == '!'

        return sql

      else
        return sql_for_field_without_tags(field, operator, v, db_table, db_field, is_custom_filter)
      end

    end
  end

  end

  module QueriesHelperPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include,InstanceMethods)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        alias_method_chain :column_content, :tags
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def column_content_with_tags(column, issue)
        value = column.value(issue)

        if value.class.name == "Array"
          if value.first.class.name == "IssueTag"
            value.map do |issue_tag|
              render :partial => "tagging/taglink", :locals => {:tag => issue_tag.tag, :project => @project}
            end.join(', ')
          end
        else
          column_content_without_tags(column, issue)
        end
      end
    end
  end

end

Query.send(:include, TaggingPlugin::QueryPatch) unless Query.included_modules.include? TaggingPlugin::QueryPatch
QueriesHelper.send(:include, TaggingPlugin::QueriesHelperPatch) unless QueriesHelper.included_modules.include? TaggingPlugin::QueriesHelperPatch
