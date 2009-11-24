
begin
  require 'narray'
rescue
  class NArray
  end
end

module Histogram

  # Returns (min, max)
  def min_max
    mn = self[0]
    mx = self[0]
    self.each do |val|
      if val < mn then mn = val end
      if val > mx then mx = val end
    end
    [mn, mx]
  end

  # Returns [bins, freqs]
  #
  #     bins = Number of bins to use or an Array/NArray specifying them
  #     tp   = :avg || :min  (:avg default) how to bin the values
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
  def histogram(bins=5, tp=:avg, *other_sets)
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
      _min, _max = xvals.min_max
      other_sets.each do |vec|
        (xvals, yvals) = have_frac_freqs ? [vec[0], vec[1]] : [vec, nil]
        v_min, v_max = xvals.min_max
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



