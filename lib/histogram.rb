
module Histogram

  # Returns (min, max)
  def min_max
    mn = self.first
    mx = self.first
    self.each do |val|
      if val < mn then mn = val end
      if val > mx then mx = val end
    end
    [mn, mx]
  end



  # Returns (bins, freqs): bins as Integers and freqs as Floats
  # bins = number of bins to use
  # tp = type of binning
  # 
  # lowest bin will be min, highest bin the max
  # unless bins.class == Array (bins specified)
  # 
  # assumes that bins are increasing 
  # if bins.kind_of?( Array ) then it will use those bins
  # bins will be returned as a new VecD object
  # avg means that the boundary between bins is at the avg between the bins
  # (rounds up )
  # min means that to fit in the bin it must be >= the bin and < the next
  # thus, values lower than first bin are not included, but all values higher
  # than last bin are included.
  # Current implementation of bins as Array is brute force and slow
  # if other sets are given, the same bins will be used for all
  # (the min/max of all sets will be used if applicable)
  # in this case returns [bins, freqs(caller), freqs1, freqs2 ...]
  #
  # FRACTIONAL FREQUENCIES: Can also deal with parallel arrays where the first
  # array is the x values to histogram and the next array is the y values (or
  # intensities) to be applied in the histogram. (checks for
  # !first_value.is_a?(Numeric))
  def histogram(bins=5, tp=:avg, *other_sets)
    all = [self] + other_sets 
    _bins = nil
    _freqs = nil
    ########################################################
    # ARRAY BINS:
    ########################################################
    if bins.kind_of? Array
      _bins = bins.map {|v| v.to_f }
      case tp
      when :avg
        freqs_ar = all.map do |vec|

          (xvals, yvals) = 
            if vec[0].is_a?(Numeric) ; [vec, nil]
            else                     ; [vec[0], vec[1]] 
            end

          #_freqs = VecI.new(bins.size, 0)
          _freqs = Array.new(bins.size, 0.0)
          break_points = [] 
          bins.each_with_index do |bin,i|
            break if i == (bins.size - 1)
            break_points << avg_ints(bin,bins[i+1]) 
          end
          xvals.each_with_index do |val,i|
            height = yvals ? yvals[i] : 1
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

          (xvals, yvals) = 
            if vec[0].is_a?(Numeric) ; [vec, nil]
            else                     ; [vec[0], vec[1]] 
            end

          #_freqs = VecI.new(bins.size, 0)
          _freqs = Array.new(bins.size, 0)
          xvals.each_with_index do |val,i|
            height = yvals ? yvals[i] : 1
            last_i = 0
            last_found_i = false
            _bins.each_with_index do |bin,i|
              if val >= bin
                last_found_i = i
              elsif last_found_i
                break
              end
            end
            if last_found_i ; _freqs[last_found_i] += height ; end
          end
          _freqs
        end
      end
      ########################################################
      # NUMBER OF BINS:
      ########################################################
    else


      # Create the scaling factor
      _min, _max = min_max
      other_sets.each do |vec|
        v_min, v_max = vec.min_max
        if v_min < _min ; _min = v_min end 
        if v_max > _max ; _max = v_max end 
      end

      dmin = _min.to_f
      conv = bins.to_f/(_max - _min)
      _bins = Array.new(bins)

      freqs_ar = all.map do |vec|

        (xvals, yvals) = 
          if vec[0].is_a?(Numeric) ; [vec, nil]
          else                     ; [vec[0], vec[1]] 
          end

        # initialize arrays
        _freqs = Array.new(bins, 0.0)
        _len = size

        # Create the histogram:
        xvals.each_with_index do |val,i|
          height = yvals ? yvals[i] : 1
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



