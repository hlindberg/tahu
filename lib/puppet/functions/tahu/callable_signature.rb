# Produces an `Array` of `Callable` signatures (parameters with types, and returned type) of functions.
#
# Returns an `Array` with one or more `Type[Callable]` describing how a function can be called,
# or how the `new` function of a data type can be called.
#
# Data type signatures are produced as function signatures for the respective type's `new` function
# except for `CatalogEntry` data types since they have different semantics and for which this function returns `undef`.
# The value `undef` is also returned for non existing functions and for data types that do not have a `new` function.
#
# @example Getting the callable signature of a function
#   notice(tahu::callable_signature("size"))
#   # Would notice: `[Callable[Variant[Collection, String, Binary]]]`
#
# @example Getting the callable signature of a data type
#   notice(tahu::callable_signature(Integer))
#   # Would notice: [Callable[Convertible, Radix, Boolean, 1, 3], Callable[NamedArgs]]
#
# See
# * `tahu::is_callable_with` for testing if a callable can be called with a given set of arguments.
# * `tahu::signature` to get more information about the signature as a data structure.
#
Puppet::Functions.create_function(:'tahu::callable_signature', Puppet::Functions::InternalFunction) do

  # @param function_name - The name of a function to get `Callable` signature(s) from
  dispatch :function_signature do
    scope_param
    required_param 'String', :function_name
    return_type 'Optional[Array[Type[Callable]]]'
  end

  # @param type - The Type to get `Callable` signature(s) from its `new` function
  dispatch :type_new_signature do
    scope_param
    required_param 'Type', :type
    return_type 'Optional[Array[Type[Callable]]]'
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
      raise ArgumentError, _('It is not possible to take the callable_signature of a variable name')
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
    func.class.dispatcher.signatures.map { |signature| signature.type }
  end
end
