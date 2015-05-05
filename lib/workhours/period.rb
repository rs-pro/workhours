module Workhours
  class Period
    attr_accessor :wday, :shift
    def initialize(wday, beginning, ending)
      @wday = wday
      beginning = Tod::TimeOfDay.parse(beginning) unless beginning.is_a?(Tod::TimeOfDay)
      ending = Tod::TimeOfDay.parse(ending) unless ending.is_a?(Tod::TimeOfDay)
      if ending.second_of_day != 0 && ending < beginning
        raise MultidayPeriodError.new()
      end
      @shift = Tod::Shift.new(beginning, ending)
    end

    def inspect
      "<Workhours::Period wday:#{wday} beginning:#{beginning.to_s} ending:#{ending.to_s}>"
    end

    def is_inside_range?(tod)
      return true if shift.beginning.second_of_day == 0 && shift.ending.second_of_day == 0
      shift.include?(tod)
    end

    def is_today?(time)
      Workhours.is_today?(wday, time)
    end
    def is_tomorrow?(time)
      Workhours.is_tomorrow?(wday, time)
    end
    def is_yesterday?(time)
      Workhours.is_yesterday?(wday, time)
    end

    def beginning
      shift.beginning
    end
    def ending
      shift.ending
    end

    def ending_time(time)
      if shift.ending.second_of_day == 0
        (time.to_date + 1).at(shift.ending)
      else
        time.to_date.at(shift.ending)
      end
    end

    def is_active?(time)
      tod = time.to_time_of_day
      if is_today?(time)
        if tod.second_of_day == 0 && ending.second_of_day == 0 && beginning.second_of_day > 0
          # 10:00-0:00 is NOT active on 0:00 of current day, but on 0:00 of next day
          false
        else
          is_inside_range?(tod)
        end
      else
        if tod.second_of_day == 0 && ending.second_of_day == 0 && is_tomorrow?(time)
          # 10:00-0:00 is active on 0:00 of next day
          # 00:00-0:00 is NOT active on 0:00 of next day
          beginning.second_of_day != 0
        else
          false
        end
      end
    end

    def to_s
      "#{wday} #{beginning.to_s}-#{ending.to_s}"
    end
    
    def overlaps?(other_day)
      if wday != other_day.wday
        return false 
      end
      
      open_inside = beginning > other_day.beginning && beginning < other_day.ending
      close_inside = ending > other_day.beginning && ending < other_day.ending
      outside = beginning < other_day.beginning && ending > other_day.ending
      #puts "#{to_s} vs #{other_day.to_s}: oi:#{open_inside} ci:#{close_inside} ou:#{outside}"
      open_inside || close_inside || outside
    end
  end
end

