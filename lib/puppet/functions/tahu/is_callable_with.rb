# Answers if one of the given `Type[Callable]` can be called with the given arguments and optional block.
#
# The function can be called with one `Type[Callable]` or an `Array[Type[Callable]]` (the later is
# what is produced by `tahu::callable_signatures()`).
#
# This function returns a `Boolean` indicating if the given function can be called or not with the given arguments and block.
#
# @Example Can size be called with an Array?
# ```puppet
# tahu::callable_signature('size').is_callable_with([]).notice
# ```
# Would notice `true`
#
Puppet::Functions.create_function(:'tahu::is_callable_with', Puppet::Functions::InternalFunction) do
  dispatch :is_callable do
    param 'Type[Callable]', :callable_t
    repeated_param 'Any', :arguments
    optional_block_param
    return_type 'Boolean'
  end

  dispatch :is_any_callable do
    param 'Array[Type[Callable]]', :callables
    repeated_param 'Any', :arguments
    optional_block_param
    return_type 'Boolean'
  end

  def is_callable(callable, *args, &block)
    callable.callable_with?(args, block)
  end

  def is_any_callable(callables, *args, &block)
    callables.any? {|c| c.callable_with?(args, block) }
  end
end
