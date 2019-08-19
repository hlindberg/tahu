Puppet::DataTypes.create_type('Tahu::ArrayBuilder') do
  interface <<-PUPPET
    attributes => {
    },
    functions => {
      add => Callable[[Any], Tahu::ArrayBuilder],
      append => Callable[[Any], Tahu::ArrayBuilder],
      build_array => Callable[[], Array],
    }
  PUPPET
  implementation do
    def add(value)
      @elements ||= []
      @elements += value.is_a?(Array) ? value : [value]
      self
    end

    def append(value)
      @elements ||= []
      @elements << value
      self
    end

    def build_array()
      @elements.dup
    end
  end
end
