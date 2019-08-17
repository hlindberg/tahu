# Converts a type in String format to an actual instance of Type
# @Example Creating an integer type
# ```puppet
# $int_type = tahu::convert_string_to_type("Integer[1,2]")
# ```
#
Puppet::Functions.create_function(:'tahu::to_type', Puppet::Functions::InternalFunction) do

  dispatch :to_type do
    scope_param
    required_param 'String', :type_string
  end

  def to_type(scope, val)
    Puppet::Pops::Types::TypeParser.singleton.parse(val, scope)
  end
end
