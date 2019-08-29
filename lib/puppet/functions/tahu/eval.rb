# Evaluates a string containing Puppet Language source and returns the result.
#
# The primary intended use case is to combine `eval` with
# `Deferred` to enable evaluating arbitrary code on the agent side
# when applying a catalog.
#
# This function can be used when there is the need to format or transform deferred
# values since doing that with only deferred values can be difficult to construct
# or impossible to achieve when a lambda is needed.
#
# The function accepts a Puppet Language string, and an optional `Hash[String, Any]`
# with a map of local variables to make available when the string is evaluated - this
# is how values can be passed from the location where a deferred `eval` is created
# to the location where it will be resolved/evaluated.
#
# @note There is a limitation when using `tahu::eval` from within a hiera 5 backend function
#   as the lookup context is not carried forward and this means that there is no
#   guard against recursive calls. In order to properly support this a change would be
#   needed in Puppet.
#   An alternative is to use the `tahu::ppyaml_key` backend function (or write a custom backend
#   along the lines of that implementation) as it provides protection against recursion.
#
# @example Using `eval`
#   tahu::eval("\$x + \$y", { 'x' => 10, 'y' => 20}) # produces 30
#   # Note the escaped `$` characters since interpolation is unwanted.
#
#   Deferred('tahu::eval' ["\$x + \$y", { 'x' => 10, 'y' => 20})] # produces 30 on the agent
#
# @example Evaluating logic on agent requiring use of "filter"
#   Deferred('tahu::eval', "local_lookup('key').filter |\$x| { \$x =~ Integer }")
#
# @example Asserting the type of value produced by an eval is simply done by calling `assert_type`
#   tahu::eval("assert_type(Integer, \$x + \$y))", { 'x' => 10, 'y' => 20})
#
# Requires Puppet 6.1.0
#
Puppet::Functions.create_function(:'tahu::eval', Puppet::Functions::InternalFunction) do
  # @param code - Puppet Language source string to evaluate
  dispatch :eval_puppet do
    scope_param
    param 'String', :code
    return_type 'Any'
  end

  # @param code - Puppet Language source string to evaluate
  # @param variables - variable names (without $) to value map of local variables to set before evaluation
  dispatch :eval_puppet_with_variables do
    scope_param
    param 'String', :code
    param 'Hash[String, Any]', :variables
    return_type 'Any'
  end

  def eval_puppet_with_variables(scope, code, variables)
    eval_puppet(scope, code, variables)
  end

  def eval_puppet(scope, code, variables = {})
    compiler = (Puppet[:tasks] ? Puppet::Pal::ScriptCompiler : Puppet::Pal::CatalogCompiler).new(scope.compiler)
    ast = compiler.parse_string(code)              # cannot get source file/line since string may travel to agent
    evaluator = compiler.send(:internal_evaluator) # private - PAL cannot yet do eval in local scope PUP-9252
    in_local_scope(scope, variables) { evaluate(evaluator, scope, ast) }
  end

  def evaluate(evaluator, scope, ast)
    if ast.is_a?(Puppet::Pops::Model::Program)
      loaders = Puppet.lookup(:loaders)
      loaders.instantiate_definitions(ast, loaders.public_environment_loader)
    end
    evaluator.evaluate(scope, ast)
  end

  def in_local_scope(scope, variables, &block)
    scope.with_guarded_scope do
      scope.ephemeral_from(variables)
      yield
    end
  end

end
