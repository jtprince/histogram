
begin
  require 'narray'
rescue loaderror
  class narray
  end
end

module histogram

  # returns (min, max)
  def self.min_max(obj)
    mn = obj[0]
    mx = obj[0]
    obj.each do |val|
      if val < mn then mn = val end
      if val > mx then mx = val end
    end
    [mn, mx]
  end

  # returns (mean, standard_dev)
  # if size == 0 returns [nil, nil]
  def self.sample_stats(obj)
    _len = obj.size
    return [nil, nil] if _len == 0
    _sum = 0.0 ; _sum_sq = 0.0
    obj.each do |val|
      _sum += val
      _sum_sq += val * val
    end
    std_dev = _sum_sq - ((_sum * _sum)/_len)
    std_dev /= ( _len > 1 ? _len-1 : 1 )
    [_sum.to_f/_len, math.sqrt(std_dev)]
  end

  def self.iqrange(obj)
    srted = obj.sort
    sz = srted.size
    if sz % 2 == 0
      median_index_hi = sz / 2
      median_index_lo = sz / 2 - 1
      dist = sz / 2 
      fq = srted[median_index_hi + dist]
      tq = srted[median_index_lo - dist]
    else
      median_index = sz / 2
      dist = (median_index + 1) / 2
      fq = srted[median_index - dist]
      tq = srted[median_index + dist]
    end
    (tq - fq).to_f
  end

  # returns(integer) takes :scott|:sturges|:fd|:middle
  #
  # middle is the median between the other three values
  #
  # inspired by {Richard Cotton's matlab
  # implementation}[http://www.mathworks.com/matlabcentral/fileexchange/21033-calculate-number-of-bins-for-histogram]
  # and the {histogram page on
  # wikipedia}[http://en.wikipedia.org/wiki/Histogram]
  def number_bins(methd=:fd)
    if methd == :middle
      [:scott, :sturges, :fd].map {|v| number_bins(v) }.sort[1]
    else
      range = (self.max - self.min).to_f
      nbins = 
        case methd
        when :scott
          (mean, stddev) = Histogram.sample_stats(self) 
          range / ( 3.5*stddev*(ar.size**(-1.0/3)) )
        when :sturges
          (Math::log(self.size)/Math::log(2)) + 1
        when :fd
          range / ( 2*Histogram.iqrange(self)*ar.size**(-1.0/3) ) 
        end
      nbins = 1 if num <= 0
      nbins.ceil.to_i
    end
  end

  # Returns [bins, freqs]
  #
  # Options:
  #
  #     :bins => :fd       Freedman-Diaconis range/(2*iqrange *n^(-1/3)) (default)
  #              :scott    Scott's method    range/(3.5σ * n^(-1/3))
  #              :sturges  Sturges' method   log_2(n) + 1
  #              :middle   the median between three above
  #              <Integer> give the number of bins
  #              <Array>   specify the bins themselves
  #
  #     :tp   => :avg      boundary is the avg between bins (default)
  #              :min      bins specify the minima for binning
  #
  #     :bin_width => <float> width of a bin (overrides :bins)
  #
  # Examples 
  #
  #    require 'histogram/array'
  #    ar = [-2,1,2,3,3,3,4,5,6,6]
  #    # these return: [bins, freqencies]
  #    ar.histogram(20)                  # use 20 bins
  #    ar.histogram([-3,-1,4,5,6], :avg) # custom bins
  #    
  #    # returns [bins, freq1, freq2 ...]
  #    (bins, *freqs) = ar.histogram(30, :avg, [3,3,4,4,5], [-1,0,0,3,3,6])
  #    (ar_freqs, other1, other2) = freqs
  #
  #    # histogramming with heights (uses the second array for heights)
  #    w_heights = [ar, [3,3,8,8,9,9,3,3,3,3]]
  #    w_heights.histogram(20) 
  #
  #    # with NArray
  #    require 'histogram/narray'
  #    NArray.float(20).random!(3).histogram(20)
  #       # => [bins, freqs]  # are both NArray.float objects
  #
  # Notes
  #
  # * The lowest bin will be min, highest bin the max unless array given.
  # * Assumes that bins are increasing.
  # * :avg means that the boundary between the specified bins is at the avg
  #   between the bins (rounds up )
  # * :min means that to fit in the bin it must be >= the bin and < the next
  #   (so, values lower than first bin are not included, but all values
  #   higher, than last bin are included.  Current implementation of custom
  #   bins is slow.
  # * if other_sets are supplied, the same bins will be used for all the sets.
  #   It is useful if you just want a certain number of bins and for the sets
  #   to share the exact same bins. In this case returns [bins, freqs(caller),
  #   freqs1, freqs2 ...]
  # * Can also deal with parallel arrays where the first array is the x values
  #   to histogram and the next array is the y values (or intensities) to be
  #   applied in the histogram. (checks for !first_value.is_a?(Numeric))
  # * Return value
  def histogram(opts={})
    DEFAULT_OPTS = {
      :bins => nil,
      :tp => :avg,
      :other_sets => []
    }

    make_freqs = lambda do |obj, len|
      if obj.is_a?(Array)
        Array.new(len, 0.0)
      elsif obj.is_a?(NArray)
        NArray.float(len)
      end
    end

    all = [self] + other_sets 
    _bins = nil
    _freqs = nil
    have_frac_freqs = !self[0].is_a?(Numeric)
    if bins.kind_of?(Array) || bins.kind_of?(NArray)
      ########################################################
      # ARRAY BINS:
      ########################################################
      _bins = 
        if bins.is_a?(Array)
          bins.map {|v| v.to_f } 
        elsif bins.is_a?(NArray)
          bins.to_f
        end
      case tp
      when :avg
        freqs_ar = all.map do |vec|

          (xvals, yvals) = have_frac_freqs ? [vec[0], vec[1]] : [vec, nil]

          _freqs = make_freqs.call(xvals, bins.size)

          break_points = [] 
          (0...(bins.size)).each do |i|
            bin = bins[i]
            break if i == (bins.size - 1)
            break_points << avg_ints(bin,bins[i+1]) 
          end
          (0...(xvals.size)).each do |i|
            val = xvals[i]
            height = have_frac_freqs ? yvals[i] : 1
            if val < break_points.first
              _freqs[0] += height
            elsif val >= break_points.last
              _freqs[-1] += height 
            else
              (0...(break_points.size-1)).each do |i| 
                if val >= break_points[i] && val < break_points[i+1]
                  _freqs[i+1] += height
                  break
                end
              end
            end
          end
          _freqs 
        end
      when :min
        freqs_ar = all.map do |vec|

          (xvals, yvals) = have_frac_freqs ? [vec[0], vec[1]] : [vec, nil]

          #_freqs = VecI.new(bins.size, 0)
          _freqs = make_freqs.call(xvals, bins.size)
          (0...(xvals.size)).each do |i|
            val = xvals[i]
            height = have_frac_freqs ? yvals[i] : 1
            last_i = 0
            last_found_j = false
            (0...(_bins.size)).each do |j|
              if val >= _bins[j]
                last_found_j = j
              elsif last_found_j
                break
              end
            end
            if last_found_j ; _freqs[last_found_j] += height ; end
          end
          _freqs
        end
      end
      ########################################################
      # NUMBER OF BINS:
      ########################################################
    else
      # Create the scaling factor

      (xvals, yvals) = have_frac_freqs ? [self[0], self[1]] : [self, nil]
      _min, _max = Histogram.min_max(xvals)
      other_sets.each do |vec|
        (xvals, yvals) = have_frac_freqs ? [vec[0], vec[1]] : [vec, nil]
        v_min, v_max = Histogram.min_max(xvals)
        if v_min < _min ; _min = v_min end 
        if v_max > _max ; _max = v_max end 
      end

      dmin = _min.to_f
      conv = bins.to_f/(_max - _min)

      _bins = 
        if self.is_a?(Array)
          Array.new(bins)
        elsif self.is_a?(NArray)
          NArray.float(bins)
        end

      freqs_ar = all.map do |vec|

        (xvals, yvals) = have_frac_freqs ? [vec[0], vec[1]] : [vec, nil]

        # initialize arrays
        _freqs = make_freqs.call(xvals, bins)
        _len = size

        # Create the histogram:
        (0...(xvals.size)).each do |i|
          val = xvals[i]
          height = have_frac_freqs ? yvals[i] : 1
          index = ((val-_min)*conv).floor
          if index == bins
            index -= 1
          end
          _freqs[index] += height
        end
        _freqs
      end

      # Create the bins:
      iconv = 1.0/conv
      case tp
      when :avg
        (0...bins).each do |i|
          _bins[i] = ((i+0.5) * iconv) + dmin
        end
      when :min
        (0...bins).each do |i|
          _bins[i] = (i * iconv) + dmin
        end
      end
    end
    [_bins] + freqs_ar
  end

  def avg_ints(one, two) # :nodoc:
    (one.to_f + two.to_f) / 2.0
  end

end



