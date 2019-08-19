# Returns the instance attributes of an `Object` or `Type`.
#
# An *instance attribute* is an attribute of a value. Only `Object` values have
# instance attributes; for example the `name` of a `Person`. Contrast this
# with a *type attribute* which is an attributes of a `Type`. The type attributes
# can be obtained with the function `tahu::type_attributes(T)` - as an example
# the `Integer` type has the type attributes `to` and `from`, but integer values
# for example `123` have no attributes - as it is just a value.
#
# This function returns a hash mapping attribute name to the data type for that attribute.
# If the given type (or type of Object) has no attributes an empty hash will be returned.
#
# See
# * `tahu::type_attributes` for how to get attributes of types
# * `tahu::get_attr` for how to get the value of an attribute
#
# @example Getting the attributes of a Type[Object]
#   type MyThing = Object[attributes => { example => String }]
#   notice(tahu::attributes(MyThing)
#   # Would notice { "example" => String }
#
# @example Getting the attributes of an Object
#   type MyThing = Object[attributes => { example => String }]
#   $a_thing = MyThing("hello")
#   notice(tahu::attributes($a_thing)
#   # Would notice { "example" => String }
#
# @example Getting the attribute names of a type results in an empty hash
#   notice(tahu::attributes(Integer))
#   # Would notice `{}`
#
Puppet::Functions.create_function(:'tahu::attributes', Puppet::Functions::InternalFunction) do

  # @param object_type - The object type to get instance attributes from
  dispatch :attributes_from_object_type do
    required_param 'Type[Object]', :object_type
    return_type 'Hash[String, Type]'
  end

  # @param type - The type to get instance attributes from
  dispatch :attributes_from_type do
    required_param 'Type', :type
    return_type 'Hash[String, Type]'
  end

  # @param an_object - An object to get instance attributes from its type
  dispatch :attributes_from_object do
    required_param 'Object', :an_object
    return_type 'Hash[String, Type]'
  end

  def attributes_from_type(val)
    # There are none
    return { }
  end

  def attributes_from_object_type(val)
    result = {}
    val.attributes.each {|name, a| result[name] = a.type }
    result
  end

  def attributes_from_object(val)
    attributes_from_object_type(val._pcore_type)
  end
end
