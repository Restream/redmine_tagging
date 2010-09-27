require_dependency 'query'

module TaggingPlugin
  module QueryPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  
    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      alias_method_chain :available_filters, :tags
      alias_method_chain :sql_for_field, :tags
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
          :type => :list,
          :values => tags,
          :order => 20
        } 
      }
  
      return @available_filters.merge(tag_filter)
    end
  
    def sql_for_field_with_tags(field, operator, v, db_table, db_field, is_custom_filter=false)
      if field == "tags"
        selected_values = values_for(field)

        sql = selected_values.collect{|val| "'#{val.downcase.gsub('\'', '')}'"}.join(',')
        sql = "(#{Issue.table_name}.id in (select taggable_id from taggings join tags on tags.id = taggings.tag_id where taggable_type='Issue' and tags.name in (#{sql})))"
        sql = "(not #{sql})" if operator == '!'

        return sql
    
      else
        return sql_for_field_without_tags(field, operator, v, db_table, db_field, is_custom_filter)
      end
    
    end
  end
  
  module ClassMethods
    # Setter for +available_columns+ that isn't provided by the core.
    def available_columns=(v)
      self.available_columns = (v)
    end
  
    # Method to add a column to the +available_columns+ that isn't provided by the core.
    def add_available_column(column)
      self.available_columns << (column)
    end
  end
  end
end

Query.send(:include, TaggingPlugin::QueryPatch) unless Query.included_modules.include? TaggingPlugin::QueryPatch
