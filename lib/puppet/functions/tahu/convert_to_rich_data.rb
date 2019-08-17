# Converts a value to a `RichData` compliant data structure
#
#
Puppet::Functions.create_function(:'tahu::convert_to_rich_data', Puppet::Functions::InternalFunction) do

  dispatch :to_rich_data do
    scope_param
    required_param 'Any', :value
  end

  def to_rich_data(scope, val)
    serialized = Puppet::Pops::Serialization::ToDataConverter.convert(val,
      :rich_data => true,
      :type_by_reference => false,
      :local_reference => false,
      :emit_warnings => true,
      :message_prefix => "data produced by convert_to_rich_data()"
      )
    return serialized
  end
end
