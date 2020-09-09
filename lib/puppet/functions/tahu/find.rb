#  Applies a parameterized block to each element in a sequence of selected entries from the first
#  argument and immediately returns the value produced by the block if it is not undef.
#
# This function can be used to find different information in an enumerable value, the index of a value,
# the value given properties of the index/key, or a derived value from original index and/or value.
#
# This function takes two mandatory arguments: the first should be an Array or a Hash or something that is
# of enumerable type (integer, Integer range, or String), and the second
# a parameterized block as produced by the puppet syntax:
#
#       $a.tahu::find |$x| { ... }
#       tahu::find($a) |$x| { ... }
#
# When the first argument is an Array (or of enumerable type other than Hash), the parameterized block
# should define one or two block parameters.
# For each application of the block, the next element from the array is selected, and it is passed to
# the block if the block has one parameter. If the block has two parameters, the first is the element's
# index, and the second the value. The index starts from 0.
#
#       $a.tahu::find |$index, $value| { ... }
#       tahu::find($a) |$index, $value| { ... }
#
# When the first argument is a Hash, the parameterized block should define one or two parameters.
# When one parameter is defined, the iteration is performed with each entry as an array of `[key, value]`,
# and when two parameters are defined the iteration is performed with key and value.
#
#       $a.tahu::find |$entry|       { ... }
#       $a.tahu::find |$key, $value| { ... }
#
# @example using find
#
#       [1,2,3].tahu::find |$val| { if $val > 1 { $val }}                 # 2
#       [5,6,7].tahu::find |$index, $val| { if $val == 7 { $index } }     # 2
#       {a=>1, b=>2, c=>3}.tahu::find |$val| { if $val[1] >1 { $val } }   # [b, 2]
#       {a=>1, b=>2, c=>3}.tahu::find |$key, $val| { if $val > 1 {$key} } # b
#       "hello".tahu::find |$char| { ... }
#       3.tahu::find |$number| { ... }
#
Puppet::Functions.create_function(:'tahu::find') do
  dispatch :find_Hash_2 do
    param 'Hash[Any, Any]', :hash
    required_block_param 'Callable[2,2]', :block
  end

  dispatch :find_Hash_1 do
    param 'Hash[Any, Any]', :hash
    required_block_param 'Callable[1,1]', :block
  end

  dispatch :find_Enumerable_2 do
    param 'Any', :enumerable
    required_block_param 'Callable[2,2]', :block
  end

  dispatch :find_Enumerable_1 do
    param 'Any', :enumerable
    required_block_param 'Callable[1,1]', :block
  end

  def find_Hash_1(hash, pblock)
    hash.each {|x,y| z = pblock.call(nil, [x,y]); return z if !z.nil? }
    nil
  end

  def find_Hash_2(hash, pblock)
    hash.each {|x,y| z = pblock.call(nil, x,y); return z if !z.nil?  }
    nil
  end

  def find_Enumerable_1(enumerable, pblock)
    enum = asserted_enumerable(enumerable)
      begin
        loop { z = pblock.call(nil, enum.next); return z if !z.nil? }
      rescue StopIteration
      end
    nil
  end

  def find_Enumerable_2(enumerable, pblock)
    enum = asserted_enumerable(enumerable)
    index = 0
    begin
      loop do
        z = pblock.call(nil, index, enum.next)
        return z if !z.nil?
        index += 1
      end
    rescue StopIteration
    end
    nil
  end

  def asserted_enumerable(obj)
    unless enum = Puppet::Pops::Types::Enumeration.enumerator(obj)
      raise ArgumentError, ("#{self.class.name}(): wrong argument type (#{obj.class}; must be something enumerable.")
    end
    enum
  end

end
