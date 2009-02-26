module AdminTableHelper

  ##
  # All helpers related to table.
  #
  def build_typus_table(model, fields, items, link_options = { } )

    returning(String.new) do |html|

      html << <<-HTML
<table>
      HTML

      html << typus_table_header(model, fields)

      items.each do |item|

        html << <<-HTML
<tr class="#{cycle('even', 'odd')}" id="item_#{item.id}">
        HTML

        fields.each do |key, value|
          case value
          when :boolean:           html << typus_table_boolean_field(key, item)
          when :datetime:          html << typus_table_datetime_field(key, item)
          when :date:              html << typus_table_datetime_field(key, item)
          when :time:              html << typus_table_datetime_field(key, item)
          when :belongs_to:        html << typus_table_belongs_to_field(key, item)
          when :tree:              html << typus_table_tree_field(key, item)
          when :position:          html << typus_table_position_field(key, item)
          when :has_and_belongs_to_many:
            html << typus_table_has_and_belongs_to_many_field(key, item)
          else
            html << typus_table_string_field(key, item, fields.first.first, link_options)
          end
        end

      ##
      # This controls the action to perform. If we are on a model list we 
      # will remove the entry, but if we inside a model we will remove the 
      # relationship between the models.
      #
      # Only shown is the user can destroy items.
      #

      if @current_user.can_perform?(model, 'delete')

        case params[:action]
        when 'index'
          perform = link_to image_tag('admin/trash.gif'), { :action => 'destroy', 
                                                            :id => item.id }, 
                                                            :confirm => 'Remove entry?', 
                                                            :method => :delete
        else
          perform = link_to image_tag('admin/trash.gif'), { :action => 'unrelate', 
                                                            :id => params[:id], 
                                                            :resource => item.class.name.tableize, 
                                                            :resource_id => item.id }, 
                                                            :confirm => "Unrelate #{model.name.humanize.singularize} from #{@resource[:class_name]}?"
        end

      end

      html << <<-HTML
<td width="10px">#{perform}</td>
</tr>
      HTML

    end

      html << "</table>"

    end

  end

  ##
  # Header of the table
  #
  def typus_table_header(model, fields)
    returning(String.new) do |html|
      headers = []
      fields.each do |key, value|

        content = I18n.t(key.humanize, :default => key.humanize)

        if (model.model_fields.map(&:first).collect { |i| i.to_s }.include?(key) || model.reflect_on_all_associations(:belongs_to).map(&:name).include?(key.to_sym)) && params[:action] == 'index'
          sort_order = case params[:sort_order]
                       when 'asc':  'desc'
                       when 'desc': 'asc'
                       end
          order_by = model.reflect_on_association(key.to_sym).primary_key_name rescue key
          switch = (params[:order_by] == key) ? sort_order : ''
          content = (link_to "<div class=\"#{switch}\">#{content}</div>", { :params => params.merge(:order_by => order_by, :sort_order => sort_order) })
        end

        headers << <<-HTML
<th>#{content}</th>
        HTML

      end
      headers << "<th>&nbsp;</th>"
      html << <<-HTML
<tr>
#{headers.join("\n")}
</tr>
      HTML
    end
  end

  def typus_table_belongs_to_field(attribute, item)
    if item.send(attribute).kind_of?(NilClass)
      "<td></td>"
    else
      "<td>#{link_to item.send(attribute).typus_name, :controller => attribute.pluralize, :action => 'edit', :id => item.send(attribute).id}</td>"
    end
  end

  def typus_table_has_and_belongs_to_many_field(attribute, item)
    <<-HTML
<td>#{item.send(attribute).map { |i| i.typus_name }.join('<br />')}</td>
    HTML
  end

  ##
  # When detection of the attributes is made a default attribute 
  # type is set. From the string_field we display other content 
  # types.
  #
  def typus_table_string_field(attribute, item, first_field, link_options = {})
    content = if first_field == attribute
                link_to item.send(attribute) || @resource[:class].typus_options_for(:nil), link_options.merge(:controller => item.class.name.tableize, :action => 'edit', :id => item.id)
              else
                item.send(attribute)
              end
    <<-HTML
<td>#{content}</td>
    HTML
  end

  def typus_table_tree_field(attribute, item)
    <<-HTML
<td>#{item.parent.typus_name if item.parent}</td>
    HTML
  end

  def typus_table_position_field(attribute, item)
    returning(String.new) do |html|
      html_position = [["Up", "move_higher"], ["Down", "move_lower"]].map do |position|
                        <<-HTML
#{link_to t(position.first), :params => params.merge(:controller => item.class.name.tableize, :action => 'position', :id => item.id, :go => position.last)}
                        HTML
                      end
      html << <<-HTML
<td>#{html_position.join('/ ')}</td>
      HTML
    end
  end

  def typus_table_datetime_field(attribute, item)

    date_format = item.class.typus_date_format(attribute)
    value = !item.send(attribute).nil? ? item.send(attribute).to_s(date_format) : @resource[:class].typus_options_for(:nil)
    return "<td>#{value}</td>\n"

  end

  def typus_table_boolean_field(attribute, item)

    boolean_icon = item.class.typus_options_for(:icon_on_boolean)
    boolean_hash = item.class.typus_boolean(attribute)

    status = item.send(attribute)

    link_text = unless item.send(attribute).nil?
                  (boolean_icon) ? image_tag("admin/status_#{status}.gif") : boolean_hash["#{status}".to_sym]
                else
                  item.class.typus_options_for(:nil) # Content is nil, so we show nil.
                end

    content = if item.class.typus_options_for(:toggle) && !item.send(attribute).nil?
                link_to link_text, { :params => params.merge(:controller => item.class.name.tableize, :action => 'toggle', :field => attribute, :id => item.id) } , :confirm => "Change #{attribute.humanize.downcase}?"
              else
                link_text
              end

    html = <<-HTML
<td align="center">#{content}</td>
    HTML

    return html

  end

end