# Returns a data structure describing the type signature (parameters with types, and returned type) of "callable" entities.
#
# The signature() function can return a signature for:
# * Functions
# * Native resource types (for example `File`).
# * Classes (i.e. created by `class` in Puppet Language).
# * user defined resource types (i.e. created by `define` in Puppet Language).
#
# *Function Signatures* are obtained by giving the function's name as a `String`.
#
# *Data Type signatures* are produced as function signatures for the respective type's `new` function
# except for `CatalogEntry` data types since they have different semantics.
# For `CatalogEntry` data types a single signature is returned and it is possible to obtain it with or without meta parameters.
#
# The `CatalogEntry` data types are:
# * `Resource[<typename>]` - used to get the signature of a resource type. Short form aliases can be used, for example `File`.
# * `Class[<classname>]` - used to get the signature of a class.
#
# @example Getting the signature of a function
#   notice(tahu::signature("size"))
#   # Would notice: `[{parameters => {arg => {type => Variant[Collection, String, Binary]}}, return_type => Any}]`
#
# @example Getting the signature of a class.
#   class testing(Integer $x, String $y) { }
#   notice(tahu::signature(Class['testing']))
#   # Would notice `{x => {type => Integer}, y => {type => String}}`
#
# @example Including meta parameters
#   notice(tahu::signature(Class['testing'], true))
#
# @example Getting the parameter-names of a class.
#   tahu::signature(Class['testing'])['parameters'].keys()
#
# @example Getting the signature of a general data type
#   notice(tahu::signature(Integer))
#   # Would notice this quite long signature:
#   # [
#   #   { parameters => {
#   #       from  => {type => Convertible = Variant[Numeric, Boolean, Pattern[/\A[+-]?\s*(?:(?:\d+)|(?:0[xX][0-9A-Fa-f]+)|(?:0[bB][01]+))\z/], Timespan, Timestamp]},
#   #       radix => {type => Radix = Variant[Default, Integer[2, 2], Integer[8, 8], Integer[10, 10], Integer[16, 16]]},
#   #       abs   => {type => Boolean, optional => true}
#   #     },
#   #     return_type => Any
#   #   },
#   #   { parameters => {
#   #     hash_args => {
#   #       type => NamedArgs = Struct[{
#   #         'from'            => Convertible = Variant[Numeric, Boolean, Pattern[/\A[+-]?\s*(?:(?:\d+)|(?:0[xX][0-9A-Fa-f]+)|(?:0[bB][01]+))\z/], Timespan, Timestamp],
#   #         Optional['radix'] => Radix = Variant[Default, Integer[2, 2], Integer[8, 8], Integer[10, 10], Integer[16, 16]],
#   #         Optional['abs']   => Boolean
#   #     }]}},
#   #     return_type => Any
#   #   }
#   # ]
#
# ### Returned values
#
# `Resource` and `Class` data types always have a single signature and use "named arguments".
# Functions use "positional arguments", and they may have multiple signatures (multiple different sequences of positional parameters).
# Functions also have "return type", support a repeating argument, and possibly a block (lambda).
# Note that the signature for general data types are for the respective `new` function of a data type, and this signature
# includes a variant where arguments are given as a struct - looking very much like an "named arguments" call.
#
# For resources and classes the returned signature is a `Hash` with parameter names as keys, and each value being a hash of:
# * `"type"` - `Type`, the type of the parameter
# * `"optional"` - `Boolean`, set to `true` if value has a default value expression, (not present otherwise)
# * `"meta"` - `Boolean`, set to `true` if value is a meta parameters - key not present for regular parameters
#
# When the optional parameter `include_meta_params` is set to `true`, the meta parameters will also be included
# in the result. This option defaults to `false`.
#
# For functions (including general data type's `new` function), the returned information is an `Array` where each entry is
# one signature. Each signature is a `Hash` with the keys:
# * `"parameters"` - `Hash`, information about each parameter - the keys are the names of the parameters and each value is
#   a hash with the keys `"type"` `Type`, and `"optional"` `Boolean`, and if the parameter is the last and repeating it will
#   also have a `"repeating"` key set to `true`. The `"optional"` key is only present if the value is `true`.
# * `"return_type"` - `Type`, the return type - is set to `Any` for functions that does not specify a return type
# * `"block_type"` - `Type`, the type of a block if a block is accepted otherwise not present. When a function accepts a block
#   the type is either a `Callable` if the block is required, or `Optional[Callable]` if the block is optional. The `Callable` data type
#   further specifies the block's parameters and their types.
#
# Since Puppet Language hashes have ordered entries, the hash also describe the position of each parameter.
#
# The `signature()` function returns `undef` in case the given function name references a function that does not exist,
# if a given data type does not exist, or if it does not have a `new` function.
# 
# *Related Information*
# * To ask if a value can be used in a call to create a new instance of a type `T` use `$val =~ Init[T]`
# * To ask if a `Callable` can be called with given values call `tahu::is_callable_with()`
#
Puppet::Functions.create_function(:'tahu::signature', Puppet::Functions::InternalFunction) do

  # @param function - the name of the function to get signature(s) from
  dispatch :function_signature do
    scope_param
    required_param 'String', :function
    return_type 'Optional[Array[Hash]]'
  end

  # @param entity - the CatalogEntry (class or resource) Type to get a signature from
  # @param include_meta_params - optional flag that when set to true will include the meta parameters of the entity
  dispatch :catalog_entry_signature do
    scope_param
    required_param 'Variant[Type[CatalogEntry], Type[Type[CatalogEntry]]]', :entity
    optional_param 'Boolean', :include_meta_params
    return_type 'Optional[Hash]'
  end

  # @param type - the Type for which signature(s) are to be produced for its `new` function
  dispatch :type_new_signature do
    scope_param
    required_param 'Type', :type
    return_type 'Optional[Array[Hash]]'
  end

  def type_new_signature(scope, type)
    # find the 'new' function for the type
    begin
      func_class = type.new_function
    rescue ArgumentError
      return nil
    end
    f = func_class.new(scope, loader)
    function_instance_signature(scope, f)
  end

  def function_signature(scope, val)
    if val =~ /^\$(.+)$/
      raise ArgumentError, _('It is not possible to take the signature of a variable name')
    end
    # signature of a function
    loaders = scope.compiler.loaders
    loader = loaders.private_environment_loader
    if loader && func = loader.load(:function, val)
      function_instance_signature(scope, func)
    else
      return nil # no such function
    end
  end

  def function_instance_signature(scope, func)
    type_factory = Puppet::Pops::Types::TypeFactory
    any_type = type_factory.any

    result = []
    func.class.dispatcher.signatures.each do |signature|
      type = signature.type # a Callable
      parameters = {}
      min, max = signature.args_range # min required, and max args
      param_names = signature.parameter_names
      param_types = type.param_types.types
      repeating = param_names[-1] if signature.last_captures_rest?
      param_names.each_with_index do |name, idx|
        parameters[name.to_s] = p = {}
        p[TYPE]      = param_types[idx]
        p[OPT]       = true if idx > min
        p[REPEATING] = true if name == repeating
      end

      return_type = type.return_type
      return_type = any_type if return_type.nil?

      this_result = { 'parameters' => parameters, 'return_type' => return_type}
      block_type = signature.block_type
      if !block_type.nil?
        this_result['block_type'] = block_type
      end

      result << this_result
    end
    return result
  end

  def catalog_entry_signature(scope, val, include_meta_params = false)
    is_class = false
    found = case val
    when Puppet::Pops::Types::PResourceType
      raise ArgumentError, _('The given resource type is a reference to a specific resource - not the type') if !val.title.nil?
      Puppet::Pops::Evaluator::Runtime3ResourceSupport.find_resource_type(scope, val.type_name)

    when Puppet::Pops::Types::PClassType
      raise  ArgumentError, _('The given class type is a reference to all classes') if val.class_name.nil?
      is_class = true
      if val.class_name == 'main' || val.class_name == ''
        Puppet::Pops::Evaluator::Runtime3ResourceSupport.find_main_class(scope)
      else
        #scope.compiler.findresource(:class, val.class_name)
        Puppet::Pops::Evaluator::Runtime3ResourceSupport.find_hostclass(scope, val.class_name)
      end

    when Puppet::Pops::Types::PTypeType
      case val.type
      when Puppet::Pops::Types::PResourceType
        # It is most reasonable to take Type[File] and Type[File[foo]] to mean the same as if not wrapped in a Type
        # Since the difference between File and File[foo] already captured in the distinction of type vs instance.
        is_defined(scope, val.type)

      when Puppet::Pops::Types::PClassType
        # Interpreted as asking if a class (and nothing else) is defined without having to be included in the catalog
        # (this is the same as asking for just the class' name, but with the added certainty that it cannot be a defined type.
        #
        raise  ArgumentError, _('The given class type is a reference to all classes') if val.type.class_name.nil?
        is_class = true
        Puppet::Pops::Evaluator::Runtime3ResourceSupport.find_hostclass(scope, val.type.class_name)
      end
    else
      raise ArgumentError, _("Invalid argument of type '%{value_class}' to 'defined'") % { value_class: val.class }
    end

    # Not found
    if found.nil?
      return nil
    end

    if found.is_a?(Puppet::Resource::Type)
      return create_params_hash(found, is_class, include_meta_params)
    else
      return builtin_hash(found, is_class, include_meta_params)
    end
  end

  NAME = 'name'.freeze
  TYPE = 'type'.freeze
  OPT  = 'optional'.freeze
  META = 'meta'.freeze
  REPEATING = 'repeating'.freeze

  def builtin_hash(rtype, is_class, include_meta_params)
    type_factory = Puppet::Pops::Types::TypeFactory
    any_type = type_factory.any
    members = {}
    if include_meta_params
      members = { NAME =>  {TYPE => type_factory.any, OPT => true, META => true}} unless is_class
      Puppet::Type.eachmetaparam do |name|
        # TODO: Once meta parameters are typed, this should change to reflect that type
        members[name.to_s] = { TYPE => any_type, OPT => true, META => true }
      end
    end
    rtype.parameters.each {|name| members[name.to_s] = { TYPE => any_type, OPT => true } }
    members
  end

  def create_params_hash(rtype, is_class, include_meta_params)
    arg_types = rtype.argument_types
    type_factory = Puppet::Pops::Types::TypeFactory
    any_type = type_factory.any
    members = {}

    if include_meta_params
      members = { NAME =>  {TYPE => any_type, OPT => true}} unless is_class
      Puppet::Type.eachmetaparam do |name|
        # TODO: Once meta parameters are typed, this should change to reflect that type
        members[name.to_s] = { TYPE => any_type, OPT => true, META => true }
      end
    end

    rtype.arguments.each_pair do |name, default|
      arg_type = arg_types[name]
      members[name.to_s] = {TYPE => arg_type.nil? ? any_type : arg_type }
      # Only include optional key if it should be true
      members[name.to_s][OPT] = true if !default.nil?
    end
    members
  end

end
