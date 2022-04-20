# This hiera5 lookup_key kind of backend function reads a yaml file and performs Puppet Language evaluation.
#
# It requires a 'path' pointing to a data file, and it can optionally perform a hiera interpolation before evaluating
# the read data structure as Puppet Source code. The 'path' is provided by hiera 5 framework from one of the inputs
# `path`, `paths`, `glob` or `globs`.
#
# All values that are strings are then evaluated as Puppet Source code. That means that strings are Puppet Language, and
# if they are to be interpreted as strings must either be quoted as `"'single quoted string'"` or `'"double quoted string"'` in
# the yaml source since the Puppet evaluation requires quotes around strings.
#
# All values inside of Array and Hash values (keys are excluded) will be recursively visisted and all strings will be replaced
# with the result of evaluating that string.
#
Puppet::Functions.create_function(:'tahu::ppyaml_key') do

  dispatch :yaml_data do
    param 'Variant[String, Numeric]', :key
    param 'Struct[{path=>String[1], Optional[hiera_interpolation]=>Boolean}]', :options
    param 'Puppet::LookupContext', :context
  end

  argument_mismatch :missing_path do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  require 'yaml'

  def yaml_data(key, options, context)
    # Recursion detection is tricky since evaluation of puppet logic can call the `lookup` function and start a 
    # new invocation. The protection here is not perfect but will detect if recursion occurs for the very same key
    # when hitting the logic here. This is done by picking up an invocation from an earlier call in the puppet context,
    # and using this invocation to check for recursion on the same key.
    #
    context_key = :'tahu::ppyaml'
    invocation, level = Puppet.lookup(context_key) { [context.invocation, 0] }
    next_level = invocation.equal?(context.invocation) ? level : level + 1
    Puppet.override({context_key => [invocation, next_level]}, "Protect against recursive lookup/eval of same key") do
      recursion_check(invocation, level, next_level, key) do
        path = options['path']
        hiera_interpolation = !!options['hiera_interpolation']

        data = context.cached_file_data(path) do |content|
          begin
            data = Puppet::Util::Yaml.safe_load(content, [Symbol], path)
            if data.is_a?(Hash)
              Puppet::Pops::Lookup::HieraConfig.symkeys_to_string(data)
            else
              msg = _("%{path}: file does not contain a valid yaml hash" % { path: path })
              raise Puppet::DataBinding::LookupError, msg if Puppet[:strict] == :error && data != false
              Puppet.warning(msg)
              {}
            end
          rescue Puppet::Util::Yaml::YamlLoadError => ex
            # YamlLoadErrors include the absolute path to the file, so no need to add that
            raise Puppet::DataBinding::LookupError, _("Unable to parse %{message}") % { message: ex.message }
          end
        end
        value = data[key]
        if value.nil?
          if !data.include?(key)
            context.not_found()
          else
            return nil # nothing to process further - just return the nil value
          end
        end

        # First perform any hiera interpolation if that is wanted
        value = context.interpolate(value) if hiera_interpolation
        do_pp_interpolation(value)
      end
    end
  end

  # Recursively evaluate strings inside hash and array values, pp evaluate all strings
  # and return all other (basically numerics) verbatim.
  #
  def do_pp_interpolation(value)
    case value
    when Array
      value.map {|v| do_pp_interpolation(v)}
    when Hash
      result = {}
      value.each_pair {|k,v| result[k] = do_pp_interpolation(v) }
      result
    when String
      call_function('tahu::eval', value)
    else
      value
    end
  end

  # If a call comes from the initial level (0) it is already checked at that level
  # Subsequent recursive calls via the "lookup" function will bump the level
  # and make a check against the initial Invocation that is passed on in the
  # puppet context, with increasing level count - there is no need to decrease it
  # since the level disappears when the level override goes out of scope.
  #
  def recursion_check(invocation, level, next_level, key, &block)
    if level == next_level # within the same level
      yield
    else
      invocation.check(key, &block)
    end
  end

  def missing_path(options, context)
    if !options['path']
      "one of 'path', 'paths' 'glob', 'globs' or 'mapped_paths' must be declared in hiera.yaml when using this lookup_key function"
    else
      "supported options are String 'path', and Boolean 'hiera_interpolation' got: '#{options}'"
    end
  end
end
