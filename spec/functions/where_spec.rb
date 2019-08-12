require 'spec_helper'

describe 'tahu::where' do
  include PuppetSpec::Compiler
  include Matchers::Resource

  it 'returns an array with two nil values when there is no callstack' do 
    is_expected.to run.with_params().and_return([nil, nil])
  end

  it 'returns [unknown, line] when file is not known but line is' do
    notices = eval_and_collect_notices(<<-PUPPET)
      function foo() {
        tahu::where()
      }
      notice(foo())
    PUPPET
    expect(notices).to include('[unknown, 2]')
  end

  it 'returns [filename, line] when both are known' do
    result = evaluate(source: <<-SOURCE, source_location: '/returned_filename.pp')
      function foo() {
        tahu::where()
      }
      foo()
    SOURCE
    expect(result).to eql(['/returned_filename.pp', 2])
  end


end
