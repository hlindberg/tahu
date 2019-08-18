# Converts a value to a `RichData` compliant data structure.
#
# This function is useful as serialization of rich data (data that cannot be directly represented with YAML/JSON data
# types alone) - for example writing the result to a yaml file for
# later reading and deserialization into actual objects using `tahu::convert_from_rich_data()`.
#
# @note The "rich data format" is the format used in a Puppet catalog.
#
# See
# * `tahu::convert_from_rich_data` for how to convert what this function returns back to runtime values
# * [Pcore Data Representation Specification](https://github.com/puppetlabs/puppet-specifications/blob/master/language/data-types/pcore-data-representation.md)
#
Puppet::Functions.create_function(:'tahu::convert_to_rich_data', Puppet::Functions::InternalFunction) do

  # @param value - The value to convert to `RichData`
  dispatch :to_rich_data do
    scope_param
    required_param 'Any', :value
    return_type 'RichData'
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
