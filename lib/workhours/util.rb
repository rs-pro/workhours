module Workhours
  module Util
    def wday_to_int(day_name)
      ALL_DAYS.find_index(day_name.to_s.downcase)
    end

    def int_to_wday(num)
      ALL_DAYS[num]
    end

    def next_day(day_name)
      int_to_wday((wday_to_int(day_name) + 1) % 7)
    end
    def prev_day(day_name)
      int_to_wday((wday_to_int(day_name) + 6) % 7)
    end

    def is_today?(day_name, time)
      time.wday == wday_to_int(day_name)
    end
    def is_tomorrow?(day_name, time)
      time.wday == wday_to_int(next_day(day_name))
    end
    def is_yesterday?(day_name, time)
      time.wday == wday_to_int(prev_day(day_name))
    end
  end
end

