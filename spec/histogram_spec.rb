require File.expand_path(File.dirname(__FILE__) + "/spec_helper.rb")

class Array
  def to_f
    self.map {|v| v.to_f }
  end
end

shared 'a histogram' do

  before do
    #@obj1 = (0..10).to_a
    #@obj2 = [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9]
  end

  it 'can make histograms (bins created on the fly)' do
    # Test with # bins:
    bins,freqs = @obj1.histogram(5)
    bins.isa @obj1.class
    freqs.isa @obj1.class
    bins.enums [1,3,5,7,9].to_f
    freqs.enums [2,2,2,2,3].to_f

    bins,freqs = @obj1.histogram(5, :tp => :min)
    bins.enums [0,2,4,6,8].to_f
    freqs.enums [2,2,2,2,3].to_f
  end

  it 'can make histograms (given bins)' do
    # Test with given bins:
    bins, freqs = @obj2.histogram([1,3,5,7,9], :tp => :avg)
    bins.enums [1,3,5,7,9].to_f
    freqs.enums [3,1,1,2,3].to_f
    bins, freqs = @obj3.histogram([1,3,5,7,9], :tp => :min)
    bins.enums [1,3,5,7,9].to_f
    freqs.enums [3,0,2,2,3].to_f
  end

  it 'can histogram multiple sets' do
    (bins, freq1, freq2, freq3) = @obj4.histogram([1,2,3,4], :tp => :avg, :other_sets => [@obj5, @obj5])
    bins.enums [1,2,3,4].to_f
    freq1.enums [2.0, 2.0, 2.0, 3.0]
    freq2.enums [0.0, 5.0, 0.0, 1.0]
    freq3.enums freq2
  end

  it 'can take height values' do
    obj2 = [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9]
    heights = Array.new(obj2.size, 3)
    obj = [obj2, heights]
    bins, freqs = obj.histogram([1,3,5,7,9], :tp => :avg)
    bins.enums [1,3,5,7,9].to_f
    freqs.enums [3,1,1,2,3].map {|v| v * 3}

    obj2 = [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9]
    heights = [10, 0, 0, 0, 50, 0, 0, 0, 0.2, 0.2]
    obj = [obj2, heights]
    (bins, freqs) = obj.histogram([1,3,5,7,9], :tp => :avg)
    bins.enums [1,3,5,7,9].to_f
    freqs.enums [10, 0, 50, 0, 0.4]
  end

  it 'works with given min and max vals' do
    [1,2,3,3,3,4,5,6,7,8].histogram(4, :min => 2, :tp => :min).first.first.is 2.0
    [1,2,3,3,3,4,5,6,7,8].histogram(4, :max => 7, :tp => :min).first.last.is 5.5 # since the bin-width is 1.5
    bs = [1,2,3,3,3,4,5,6,7,8].histogram(4, :min => 2, :max => 7, :tp => :min)
    bs.first.first.is 2.0
    bs.first.last.is 5.75 # bin-width of 1.25
  end

end

TestArrays = [[0,1,2,3,4,5,6,7,8,9,10], [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9],
  [-1, 0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9, 10], [1, 1, 2, 2, 3, 3, 4, 4, 4],
  [2, 2, 2, 2, 2, 4]]

require 'histogram/array'
class LilClass < Array
  include Histogram
end

describe 'calculating bins' do
  it 'calculates :sturges, :scott, :fd, or :middle' do
    answers = [6,3,4,4]
    [:sturges, :scott, :fd, :middle].zip(answers) do |mth, answ|
      ar = LilClass.new([0,1,2,2,2,2,2,3,3,3,3,3,3,3,3,3,5,5,9,9,10,20,15,15,15,16,17])
      # these are merely frozen, not checked to see if correct
      ar.number_bins(mth).is answ
    end
  end
end

describe 'histogramming an Array' do
  before do
    TestArrays.each_with_index do |ar,i|
      instance_variable_set("@obj#{i+1}", ar)
    end
  end
  behaves_like 'a histogram'
end

begin
  require 'histogram/narray'
  describe 'histogramming an NArray' do
    before do
      TestArrays.each_with_index do |ar,i|
        instance_variable_set("@obj#{i+1}", NArray.to_na(ar).to_f)
      end
    end
    behaves_like 'a histogram'
  end
rescue LoadError
  puts ""
  puts "YOU NEED NArray installed to run NArray tests!"
  puts ""
end
