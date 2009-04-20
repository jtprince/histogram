require 'rubygems'
require 'minitest/spec'

require 'histogram'

MiniTest::Unit.autorun

class Array
  include Histogram
  
  def to_floats
    self.map {|v| v.to_f }
  end
end

class HistSpec < MiniTest::Spec

  it 'can make histograms (bins created on the fly)' do
    # Test with # bins:
    obj1 = Array.new(11)
    (0...11).each do |i|
      obj1[i] = i
    end
    bins,freqs = obj1.histogram(5)
    bins.class.must_equal Array
    freqs.class.must_equal Array
    bins.must_equal [1,3,5,7,9]
    freqs.must_equal [2,2,2,2,3].to_floats
    bins,freqs = obj1.histogram(5, :min)
    bins.must_equal [0,2,4,6,8]
    freqs.must_equal [2,2,2,2,3].to_floats
  end

  it 'can make histograms (given bins)' do
    # Test with given bins:
    obj2 = [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9]
    bins, freqs = obj2.histogram([1,3,5,7,9], :avg)
    bins.must_equal [1,3,5,7,9].to_floats
    freqs.must_equal [3,1,1,2,3]
    obj3 = [-1, 0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9, 10].to_floats
    bins, freqs = obj3.histogram([1,3,5,7,9], :min)
    bins.must_equal [1,3,5,7,9]
    freqs.must_equal [3,0,2,2,3].to_floats
  end
end
