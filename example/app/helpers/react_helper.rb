# frozen_string_literal: true

module ReactHelper
  def react_component(component, props = {})
    tag.div(
      "",
      data: {
        react_component: component,
        react_props: ERB::Util.json_escape(props.to_json)
      }
    )
  end
end
