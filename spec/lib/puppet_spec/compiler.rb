module PuppetSpec; module Compiler
  module_function

  def compile_to_catalog(string, node = Puppet::Node.new('test'))
    Puppet[:code] = string
    # see lib/puppet/indirector/catalog/compiler.rb#filter
    Puppet::Parser::Compiler.compile(node).filter { |r| r.virtual? }
  end

  # Does not removed virtual resources in compiled catalog (i.e. keeps unrealized)
  def compile_to_catalog_unfiltered(string, node = Puppet::Node.new('test'))
    Puppet[:code] = string
    # see lib/puppet/indirector/catalog/compiler.rb#filter
    Puppet::Parser::Compiler.compile(node)
  end

  def compile_to_ral(manifest, node = Puppet::Node.new('test'))
    catalog = compile_to_catalog(manifest, node)
    ral = catalog.to_ral
    ral.finalize
    ral
  end

  def compile_to_relationship_graph(manifest, prioritizer = Puppet::Graph::SequentialPrioritizer.new)
    ral = compile_to_ral(manifest)
    graph = Puppet::Graph::RelationshipGraph.new(prioritizer)
    graph.populate_from(ral)
    graph
  end

  def apply_compiled_manifest(manifest, prioritizer = Puppet::Graph::SequentialPrioritizer.new)
    catalog = compile_to_ral(manifest)
    if block_given?
      catalog.resources.each { |res| yield res }
    end
    transaction = Puppet::Transaction.new(catalog,
                                         Puppet::Transaction::Report.new,
                                         prioritizer)
    transaction.evaluate
    transaction.report.finalize_report

    transaction
  end

  def apply_with_error_check(manifest)
    apply_compiled_manifest(manifest) do |res|
      res.expects(:err).never
    end
  end

  def order_resources_traversed_in(relationships)
    order_seen = []
    relationships.traverse { |resource| order_seen << resource.ref }
    order_seen
  end

  def collect_notices(code, node = Puppet::Node.new('foonode'))
    # Set the current environment in the node (test harness has already created one to use)
    node.environment = Puppet.lookup(:current_environment)
    Puppet[:code] = code
    compiler = Puppet::Parser::Compiler.new(node)
    node.environment.check_for_reparse
    logs = []
    Puppet::Util::Log.with_destination(Puppet::Test::LogCollector.new(logs)) do
      yield(compiler)
    end
    logs = logs.select { |log| log.level == :notice }.map { |log| log.message }
    logs
  end

  def eval_and_collect_notices(code, node = Puppet::Node.new('foonode'), topscope_vars = {})
    collect_notices(code, node) do |compiler|
      unless topscope_vars.empty?
        scope = compiler.topscope
        topscope_vars.each {|k,v| scope.setvar(k, v) }
      end
      if block_given?
        compiler.compile do |catalog|
          yield(compiler.topscope, catalog)
          catalog
        end
      else
        compiler.compile
      end
    end
  end

  # Compiles a catalog, and if source is given evaluates it and returns its result.
  # The catalog is returned if no source is given.
  # Topscope variables are set before compilation
  # Uses a created node 'testnode' if none is given.
  # (Parameters given by name)
  #
  def evaluate(code: 'undef', source: nil, node: Puppet::Node.new('testnode'), variables: {}, source_location: nil)
    node.environment = Puppet.lookup(:current_environment)
    source_location = caller[0] unless source_location
    Puppet[:code] = code
    compiler = Puppet::Parser::Compiler.new(node)
    unless variables.empty?
      scope = compiler.topscope
      variables.each {|k,v| scope.setvar(k, v) }
    end

    if source.nil?
      compiler.compile
      # see lib/puppet/indirector/catalog/compiler.rb#filter
      return compiler.filter { |r| r.virtual? }
    end

    # evaluate given source is the context of the compiled state and return its result
    compiler.compile do |catalog |
      ast = Puppet::Pops::Parser::EvaluatingParser.singleton.parse_string(source, source_location)
      bridged = Puppet::Parser::AST::PopsBridge::Program.new(ast, {:file => source_location})
      # define all catalog types
      compiler.environment.known_resource_types.import_ast(bridged, "")
      bridged.evaluate(compiler.topscope)

      Puppet::Pops::Parser::EvaluatingParser.singleton.evaluate(compiler.topscope, ast)
    end
  end
end
end
