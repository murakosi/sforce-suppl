class Hash
  def tree
    a = []
    each do |key, value|
      case value
      when String
        a << "#{key}(#{value.class})"
      when Hash
        a << key
        a.concat value.tree.flatten.map{|s| "  " + s }
      when Array
        a << "#{key}(Array of #{value[0].class})"
        a << value[0].tree.map{|s| "  " + s } if Hash === value[0]
      else
        a << "#{key}(#{value.class})"
      end
    end
    a
  end
end