Puppet::DataTypes.create_type('Tahu::HashBuilder') do
  interface <<-PUPPET
    attributes => {
    },
    functions => {
      add => Callable[[Any, Any], Tahu::HashBuilder],
      build_hash => Callable[[], Hash],
    }
  PUPPET
  implementation do
    def add(key, value)
      @elements ||= {}
      @elements[key] = value
      self
    end

    def build_hash()
      @elements.dup
    end
  end
end
