# Returns the value of a given attribute of an Object or Type.
#
# @note It is only `Object` and `Type` values that have attributes.
# @note The Object attribute `constants` can only be set when initializing - the result is a constant attribute.
#   An error is thus raised if trying to read the `'constants'` attribute. (This may change in a future version
#   as it would be possible to reverse engineer this information).
#
# See
# * `tahu::attributes` for how to get instance attribute names
# * `tahu::type_attributes` for how to get type attribute names
#
# @example Get attributes from a data type
#   notice(Integer[10,100].tahu::get_attr('to'))
#   # Would notice: 100
#
# @example Get attributes from an Object
#   type MyThing = Object[attributes => {name => String}]
#   $a_thing = MyThing("banana")
#   notice($a_thing.tahu::get_attr('name'))
#   # Would notice: "banana"
#
# @example Get attributes from a Type[Object]
#   type MyThing = Object[attributes => {name => String}]
#   notice(MyThing.tahu::get_attr('attributes'))
#   # Would notice: {name => String}
#
#
Puppet::Functions.create_function(:'tahu::get_attr', Puppet::Functions::InternalFunction) do

  # @param object_type - The Object type from which an attribute is wanted (i.e. attributes that define an Object type)
  # @param name - The name of the attribute
  # @return Any
  dispatch :get_object_type_attribute do
    required_param 'Type[Object]', :object_type
    required_param 'String', :name
  end

  # @param type - The Type from which an attribute is wanted (i.e. a type attribute/parameter)
  # @param name - The name of the attribute
  # @return Any
  dispatch :get_type_attribute do
    required_param 'Type', :type
    required_param 'String', :name
  end

  # @param value - The Object from which an attribute is wanted
  # @param name - The name of the attribute
  # @return Any
  dispatch :get_object_attribute do
    required_param 'Object', :value
    required_param 'String', :name
  end


  def get_type_attribute(val, name)
    get_it(val, get_type_attributes(val), name)
  end

  def get_type_attributes(val)
    pcore_type = val._pcore_type
    parameter_info = pcore_type.parameter_info(val.class)
    parameter_info[0].zip(parameter_info[1]).to_h
  end

  def get_object_type_attribute(val, name)
    if name == 'constants'
      raise ArgumentError, "The attribute 'constants' can only be set when creating the type and can not be read."
    end
    init_hash = val._pcore_init_hash
    attributes = val._pcore_type.members['_pcore_init_hash'].type.hashed_elements
    if attributes[name]
      init_hash[name]
    else
      raise ArgumentError, "A value of type 'Type[#{init_hash['name']}]' does not have an attribute named: '#{name}'"
    end
  end

  def get_object_type_attributes(val)
    result = {}
    val.attributes.each {|name, a| result[name] = a.type }
    result
  end

  def get_object_attribute(val, name)
    get_it(val, get_object_attributes(val), name)
  end

  def get_object_attributes(val)
    get_object_type_attributes(val._pcore_type)
  end

  def get_it(val, attributes, name)
    if attributes[name]
      val.send(name.to_sym)
    else
      no_such_attribute(val, name)
    end
  end

  def no_such_attribute(val, name)
    tc = Puppet::Pops::Types::TypeCalculator
    val_type = tc.generalize(tc.infer(val))
    raise ArgumentError, "A value of type '#{val_type}' does not have an attribute named: '#{name}'"
  end
end
