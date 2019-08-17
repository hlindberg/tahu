# Returns the value of a given attribute of an Object or Type
#
Puppet::Functions.create_function(:'tahu::get_attr', Puppet::Functions::InternalFunction) do

  dispatch :get_object_type_attribute do
    required_param 'Type[Object]', :value
    required_param 'String', :name
  end

  dispatch :get_type_attribute do
    required_param 'Type', :value
    required_param 'String', :name
  end

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
    get_it(val, get_object_type_attributes(val), name)
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
