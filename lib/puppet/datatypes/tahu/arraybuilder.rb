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
    # Adds the content of a given Array, and appends any other value.
    # This ArrayBuilder is mutated to hold the new content and is then returned
    # to allow chaining.
    #
    def add(value)
      @elements ||= []
      @elements += value.is_a?(Array) ? value : [value]
      self
    end

    # Appends the given value to any content in this ArrayBuilder.
    # This ArrayBuilder is mutated to hold the new content and is then returned
    # to allow chaining.
    #
    def append(value)
      @elements ||= []
      @elements << value
      self
    end

    # Returns a copy of the built array.
    # This returned array is unaffected by subsequent operations on this ArrayBuilder.
    def build_array()
      @elements.dup
    end
  end
end
