# Converts a value from a `RichData` compliant data structure to the actual data.
# This is the reverse of `tahu::convert_to_rich_data()`.
#
Puppet::Functions.create_function(:'tahu::convert_from_rich_data', Puppet::Functions::InternalFunction) do

  dispatch :from_rich_data do
    scope_param
    required_param 'RichData', :value
  end

  def from_rich_data(scope, val)
    Puppet::Pops::Serialization::FromDataConverter.convert(val)
  end
end
