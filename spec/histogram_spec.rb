require 'spec_helper'

require 'histogram'

RSpec::Matchers.define :be_within_rounding_error_of do |expected|
  match do |actual|
    (act, exp) = [actual, expected].map {|ar| ar.map {|v| v.to_f.round(8) } }
    act.should == exp
  end
end

shared_examples 'something that can histogram' do
  it 'makes histograms with the specified number of bins' do
    (bins, freqs) = obj0.histogram(5)
    [bins, freqs].each {|ar| ar.should be_a(obj0.class) }
    [bins,freqs].zip( [ [1,3,5,7,9], [2,2,2,2,3] ] ).each do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'returns bins as the min boundary if given that option' do
    (bins, freqs) = obj0.histogram(5, :bin_boundary => :min)
    [bins, freqs].zip( [ [0,2,4,6,8], [2,2,2,2,3] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'makes histograms when given the bins' do
    bins, freqs = obj1.histogram([1,3,5,7,9])
    [bins, freqs].zip( [ [1,3,5,7,9], [3,1,1,2,3] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'interprets bins as the min boundary when given the bin_boundary option' do
    bins, freqs = obj2.histogram([1,3,5,7,9], :bin_boundary => :min)
    [bins, freqs].zip( [ [1,3,5,7,9], [3,0,2,2,3] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'can histogram multiple sets' do
    (bins, freq1, freq2, freq3) = obj3.histogram([1,2,3,4], :other_sets => [obj4, obj4])
    bins.should be_within_rounding_error_of [1,2,3,4]
    freq1.should be_within_rounding_error_of [2.0, 2.0, 2.0, 3.0]
    freq2.should be_within_rounding_error_of [0.0, 5.0, 0.0, 1.0]
    freq3.should be_within_rounding_error_of freq2
  end

  it 'works with a given min val' do
    (bins, freqs) = obj5.histogram(4, :min => 2, :bin_boundary => :min)
    [bins, freqs].zip( [ [2.0, 3.5, 5.0, 6.5], [4.0, 1.0, 2.0, 3.0] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'works with a given max val' do
    (bins, freqs) = obj5.histogram(4, :max => 7, :bin_boundary => :min)
    [bins, freqs].zip( [ [1.0, 2.5, 4.0, 5.5] ,[2.0, 3.0, 2.0, 3.0] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'works with given min/max vals' do
    (bins, freqs) = obj5.histogram(4, :min => 2, :max => 7, :bin_boundary => :min)
    [bins, freqs].zip( [ [2.0, 3.25, 4.5, 5.75], [4.0, 1.0, 1.0, 4.0] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'can use equal weights' do
    weights = Array.new(obj1.size, 3)
    bins, freqs = obj1.histogram([1,3,5,7,9], :weights => weights)
    [bins, freqs].zip( [ [1,3,5,7,9], [3,1,1,2,3].map {|v| v * 3} ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

  it 'can use unequal weights' do
    weights = [10, 0, 0, 0, 50, 0, 0, 0, 0.2, 0.2]
    (bins, freqs) = obj1.histogram([1,3,5,7,9], :weights => weights)
    [bins, freqs].zip( [ [1,3,5,7,9], [10, 0, 50, 0, 0.4] ] ) do |ar, exp|
      ar.should be_within_rounding_error_of exp
    end
  end

end

describe Histogram do
  tmp = { 
    obj0: (0..10).to_a,
    obj1: [0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9],
    obj2: [-1, 0, 1, 1.5, 2.0, 5.0, 6.0, 7, 8, 9, 9, 10], 
    obj3: [1, 1, 2, 2, 3, 3, 4, 4, 4],
    obj4: [2, 2, 2, 2, 2, 4],
    obj5: [1,2,3,3,3,4,5,6,7,8],
  }
  data = tmp.each {|k,v| [k, v.map(&:to_f).extend(Histogram)] }

  let(:data) { data }

  data.each do |obj, ar|
    let(obj) { ar.map(&:to_f).extend(Histogram) }
  end

  describe Array do
    it_behaves_like 'something that can histogram'
  end

  begin
    describe NArray do
      data.each do |obj, ar|
        let(obj) { NArray.to_na(ar).to_f.extend(Histogram) }
      end
      it_behaves_like 'something that can histogram'
    end
  rescue
    puts ""
    puts "YOU NEED NArray installed to run NArray tests!"
    puts ""
  end

  describe 'calculating bins' do
    it 'calculates :sturges, :scott, :fd, or :middle' do
      answers = [6,3,4,4]
      [:sturges, :scott, :fd, :middle].zip(answers) do |mth, answ|
        ar = [0,1,2,2,2,2,2,3,3,3,3,3,3,3,3,3,5,5,9,9,10,20,15,15,15,16,17].extend(Histogram)
        # these are merely frozen, not checked to see if correct
        ar.number_bins(mth).should == answ
      end
    end
  end
end

