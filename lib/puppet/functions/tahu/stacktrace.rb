# Returns a full Puppet stacktrace.
#
# This function returns an `Array[Tuple[String, Integer]]` where each tuple represents a call on the form
# `[<file>, <line>]`. The first entry in the array is the location calling the `stacktrace()` function.
#
# If "file" is not know (for example when called from the command line) it
# is set to "unknown".
#
# @example unknown location
#   puppet apply -e 'notice(tahu::stacktrace())'
#   # Would produce: [[unknown, 1]]
#
# Also see `tahu::where()` for getting only the top of the stack (which is much faster than getting the entire stack
# and extracting only the immediate caller).
#
# @note (This function uses Puppet's Puppet::Pops::PuppetStack Ruby API. If something is not showing in the stack
#   then this is a problem in Puppet, not in this function).
#
Puppet::Functions.create_function(:'tahu::stacktrace', Puppet::Functions::InternalFunction) do
  # @return 'Array[Tuple[String, Integer]]'
  def stacktrace()
    Puppet::Pops::PuppetStack.stacktrace
  end
end