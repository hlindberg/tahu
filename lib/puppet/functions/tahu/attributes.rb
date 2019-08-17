# Returns the attributes of an Object or Type
# The returned value is a hash mapping attribute name to the data type for that attribute.
#
# @Example Getting the attribute names of a type
# ```puppet
# notice(tahu::attributes(Integer)).keys
# # Would notice `["to", "from"]`
# ```
#
# @Example getting the attributes of a Type[Object]
# ```puppet
# type MyThing = Object[attributes => { example => String }]
# notice(tahu::attributes(MyThing)
# # Would notice { "example" => String }
# ```puppet
#
# @Example getting the attributes of an Object
# ```puppet
# type MyThing = Object[attributes => { example => String }]
# $a_thing = MyThing("hello")
# notice(tahu::attributes($a_thing)
# # Would notice { "example" => String }
# ```puppet
#
# If the given type (or type of Object) has no attributes and empty hash will be returned.
#
Puppet::Functions.create_function(:'tahu::attributes', Puppet::Functions::InternalFunction) do

  dispatch :get_object_type_attributes do
    required_param 'Type[Object]', :value
    return_type 'Hash[String, Type]'
  end

  dispatch :get_type_attributes do
    required_param 'Type', :value
    return_type 'Hash[String, Type]'
  end

  dispatch :get_object_attributes do
    required_param 'Object', :value
    return_type 'Hash[String, Type]'
  end


  def get_type_attributes(val)
    pcore_type = val._pcore_type
    parameter_info = pcore_type.parameter_info(val.class)
    parameter_info[0].zip(parameter_info[1]).to_h
  end

  def get_object_type_attributes(val)
    result = {}
    val.attributes.each {|name, a| result[name] = a.type }
    result
  end

  def get_object_attributes(val)
    get_object_type_attributes(val._pcore_type)
  end
end
