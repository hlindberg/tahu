# Answers if one of the given `Type[Callable]` can be called with the given arguments and optional block.
#
# The function can be called with one `Type[Callable]` or an `Array[Type[Callable]]` (the later is
# what is produced by `tahu::callable_signatures()`).
#
# This function returns a `Boolean` indicating if the given function can be called or not with the given arguments and block.
#
# @example Can size be called with an Array?
#   tahu::callable_signature('size').is_callable_with([]).notice
#   # Would notice true
#
Puppet::Functions.create_function(:'tahu::is_callable_with', Puppet::Functions::InternalFunction) do

  # @param callable_t - a Callable to check if it can be called
  # @param arguments - none, one or more arguments to check if they can be used to call the `Callable`
  # @param block - the function accepts an optional lambda that is used with Callable's that accepts lambdas
  dispatch :is_callable do
    param 'Type[Callable]', :callable_t
    repeated_param 'Any', :arguments
    optional_block_param :block
    return_type 'Boolean'
  end

  # @param callables - an Array of Callable to check if one of them can be called
  # @param arguments - none, one or more arguments to check if they can be used to call the `Callable`
  # @param block - the function accepts an optional lambda that is used with Callable's that accepts lambdas
  dispatch :is_any_callable do
    param 'Array[Type[Callable]]', :callables
    repeated_param 'Any', :arguments
    optional_block_param :block
    return_type 'Boolean'
  end

  def is_callable(callable, *args, &block)
    callable.callable_with?(args, block)
  end

  def is_any_callable(callables, *args, &block)
    callables.any? {|c| c.callable_with?(args, block) }
  end
end
