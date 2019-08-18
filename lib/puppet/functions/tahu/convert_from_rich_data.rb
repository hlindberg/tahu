# Converts a value from a `RichData` compliant data structure to the actual runtime values.
#
# This function is useful as deserialization of a rich data structure - for example something read from
# a yaml file. This is the reverse of `tahu::convert_to_rich_data()`.
#
# See
# * `tahu::convert_to_rich_data` for how to serialize.
# * [Pcore Data Representation Specification](https://github.com/puppetlabs/puppet-specifications/blob/master/language/data-types/pcore-data-representation.md)
#
#
# @example Deserializing a value
#   $r = /this is a regexp/
#   $serialized = tahu::convert_to_rich_data($r)
#   $deserialized = tahu::convert_from_rich_data($serialized)
#   notice( $deserialized == $r)
#   # would notice: true
#
Puppet::Functions.create_function(:'tahu::convert_from_rich_data', Puppet::Functions::InternalFunction) do

  # @param value - The rich data value to convert from
  dispatch :from_rich_data do
    scope_param
    required_param 'RichData', :value
    return_type 'Any'
  end

  def from_rich_data(scope, val)
    Puppet::Pops::Serialization::FromDataConverter.convert(val)
  end
end
