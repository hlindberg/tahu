# Returns the type attributes of a `Type`
#
# The returned value is a hash mapping attribute name to the data type for that attribute.
# If the given type (or type of Object) has no attributes an empty hash will be returned.
#
# @note For `Type[Object]` values the returned attributes are for the object *type* not the attributes
#   of instances of that type. Use `tahu::attributes` to get the *instance attributes*.
#
# @example Getting the type attribute names of a `Type`
#   tahu::type_attributes(Integer).keys.notice
#   # Would notice ["to", "from"]
#
# @example Getting the type attributes of a `Type[Object]`
#   type MyThing = Object[attributes => { example => String }]
#   tahu::attributes(MyThing).keys
#   # Would notice [name, parent, type_parameters, attributes, constants, functions, equality, equality_include_type, checks, annotations]
#   # Note that 'example' is an instance attribute and it is not included
#
# @example Getting the attributes of an `Object`
#   type MyThing = Object[attributes => { example => String }]
#   $a_thing = MyThing("hello")
#   notice(tahu::attributes($a_thing)
#   # Would notice { "example" => String }
#
#
Puppet::Functions.create_function(:'tahu::type_attributes', Puppet::Functions::InternalFunction) do

  # @param object_type - The Type[Object] to get type attributes from
  dispatch :type_attributes_from_object_type do
    required_param 'Type[Object]', :object_type
    return_type 'Hash[String, Type]'
  end

  # @param type - The Type to get type attributes from
  dispatch :type_attributes_from_type do
    required_param 'Type', :type
    return_type 'Hash[String, Type]'
  end

  def type_attributes_from_type(val)
    pcore_type = val._pcore_type
    parameter_info = pcore_type.parameter_info(val.class)
    parameter_info[0].zip(parameter_info[1]).to_h
  end

  def type_attributes_from_object_type(val)
    attributes = val._pcore_type.members['_pcore_init_hash'].type.hashed_elements
    result = {}
    attributes.each {|name, a| result[name] = a.value_type }
    result
  end
end
