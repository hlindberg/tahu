require 'spec_helper'

describe 'tahu::stacktrace' do
  include PuppetSpec::Compiler
  include Matchers::Resource

  it 'returns an empty array when there is no callstack' do
    is_expected.to run.with_params().and_return([])
  end

  it 'returns [filename, line] tuples for all entries on the stack' do
    result = evaluate(source: <<-SOURCE, source_location: '/returned_filename.pp')
      function foo() {
        tahu::stacktrace()
      }
      foo()
    SOURCE
    expect(result).to eql([["/returned_filename.pp", 2], ["/returned_filename.pp", 4]])
  end
end
