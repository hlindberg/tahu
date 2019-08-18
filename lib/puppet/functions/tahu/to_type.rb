# Converts a type in String format to an actual instance of Type.
#
# This is useful when reading a data type from for example a YAML file and
# a real data type is wanted to for example match a value against the read data type.
#
# @example Creating an integer type
#   $int_type = tahu::convert_string_to_type("Integer[1,2]")
#   notice( 2 =~ $int_type)
#   # Would notice: true
#
Puppet::Functions.create_function(:'tahu::to_type', Puppet::Functions::InternalFunction) do

  # @param type_string - a puppet data type in string form for which a real runtime data type is wanted
  # @return 'Type'
  dispatch :to_type do
    scope_param
    required_param 'String', :type_string
  end

  def to_type(scope, val)
    Puppet::Pops::Types::TypeParser.singleton.parse(val, scope)
  end
end
