# Evaluates a string containing Puppet Language source.
# The primary intended use case is to combine `eval` with
# `Deferred` to enable evaluating arbitrary code on the agent side
# when applying a catalog.
#
# @example Using `eval`
#
# ```puppet
# tahu::eval("\$x + \$y", { 'x' => 10, 'y' => 20}) # produces 30
# ```
#
# Note the escaped `$` characters since interpolation is unwanted.
#
# ```puppet
# Deferred('tahu::eval' ["\$x + \$y", { 'x' => 10, 'y' => 20})] # produces 30 on the agent
# ```
#
# This function can be used when there is the need to format or transform deferred
# values since doing that with only deferred values can be difficult to construct
# or impossible to achieve when a lambda is needed.
#
# @example Evaluating logic on agent requiring use of "filter"
#
# ```puppet
# Deferred('tahu::eval', "local_lookup('key').filter |\$x| { \$x =~ Integer }")
# ```
#
# To assert the return type - this is simply done by calling `assert_type`
# as part of the string to evaluate.
#
# @example
# ```puppet
# tahu::eval("assert_type(Integer, \$x + \$y))", { 'x' => 10, 'y' => 20})
# ```
# @since 0.1.0 - requires Puppet 6.1.0
#
Puppet::Functions.create_function(:'tahu::eval', Puppet::Functions::InternalFunction) do
  dispatch :eval_puppet do
    scope_param             # Due to PUP-9252 must use scope here instead of compiler_param
    param 'String', :code
    optional_param 'Hash[String, Any]', :variables
  end

  # NOTE: When PUP-9252 is in place the method below can be changed to this one-liner:
  #  def eval_puppet(compiler, code, variables = {})
  #    compiler.in_local_scope(variables) { compiler.evaluate_string(code) }
  #  end
  # Then also:
  #   * use compiler_param instead of scope_param in the dispatcher.
  #   * remove the two supporting methods `evaluate` and `in_local_scope`


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
