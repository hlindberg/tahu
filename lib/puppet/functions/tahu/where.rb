# Returns a tuple describing file, and line of the manifest location where this function was called.
#
# When the call to `where()` is from a source string provided via an API or command line, the "file" entry will
# be set to the string "unknown".
# In case the function is not called from a puppet manifest, an array of `[undef, undef]` will
# be returned.
#
# @see `tahu::stacktrace()` for getting the full stacktrace.
Puppet::Functions.create_function(:'tahu::where', Puppet::Functions::InternalFunction) do
  dispatch :where do
    return_type 'Tuple[Optional[String], Optional[Integer]]'
  end

  def where()
    # get file, line if available, else they are set to nil
    file, line = Puppet::Pops::PuppetStack.top_of_stack
    return [file, line]
  end
end