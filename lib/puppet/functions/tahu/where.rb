# Returns an array with [file, line] of the manifest calling this function.
# When the call is from source that does not come from a function, the "file" entry will
# be set to the string "unknown".
# In case the function is not called from a puppet manifest, an array of `[undef, undef]` will
# be returned.
#
# Also see `tahu::stacktrace()` for getting the full stacktrace.
#

Puppet::Functions.create_function(:'tahu::where', Puppet::Functions::InternalFunction) do
  def where()
    # get file, line if available, else they are set to nil
    file, line = Puppet::Pops::PuppetStack.top_of_stack
    return [file, line]
  end
end