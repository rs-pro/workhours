module Workhours
  DEFAULTS = {
    holidays: [],
    open:     '09:00',
    close:    '18:00',
    week:     %w(mon tue wed thu fri),
    hours:    [],
  }
  class Week
    attr_reader *DEFAULTS.keys

    def initialize(options = {})
      DEFAULTS.each_pair do |k, v|
        instance_variable_set("@#{k}", v.dup)
      end
      options.each_pair do |k, v|
        instance_variable_set("@#{k}", v.dup)
      end

      @export_hours = {}

      if hours.empty?
        week.each do |wday|
          hours.push Workhours::Period.new(wday, open, close)
        end
      else
        @export_hours = hours.dup
        @hours = hours.map do |h|
          if h.is_a?(Workhours::Period)
            h
          else
            pr = h.split(' ')
            times = pr[1].split('-')
            beginning = TimeOfDay.parse(times[0])
            ending = TimeOfDay.parse(times[1])
            if ending < beginning
              [Workhours::Period.new(pr[0], times[0], "0:00"), Workhours::Period.new(Workhours.next_day(pr[0]), "0:00", times[1])]
            else
              Workhours::Period.new(pr[0], times[0], times[1])
            end
          end
        end.flatten
      end
      raise NoHoursError.new if @hours.empty?
    end

    def export(holidays: true)
      ret = {}
      if @export_hours.empty?
        (DEFAULTS.keys - [:hours]).each do |k|
          ret[k] = send(k)
        end
      else
        ret[:hours] = @export_hours
      end

      if holidays
        ret[:holidays] = @holidays
      end
      ret
    end

    def inspect
      "<Workhours::Week #{export.inspect}>"
    end

    def hours_active(time)
      hours.select { |h| h.is_active?(time) }
    end

    def is_open?(time = Time.now)
      !hours_active(time).first.nil? && !is_holiday?(time)
    end
    def is_closed?(time = Time.now)
      !is_open?(time)
    end
    def hours_on(date)
      if is_holiday?(date)
        []
      else
        hours.select { |h| h.is_today?(date) }.sort_by { |h| h.beginning }
      end
    end
    def is_open_on?(date)
      hours_on(date).first.nil? && !is_holiday?(date)
    end

    def is_holiday?(date)
      holidays.include?(date.to_date)
    end

    def opens_at(time = Time.now)
      if is_open?(time)
        nil
      else
        next_open_time(time)
      end
    end
    def closes_at(time = Time.now)
      if is_closed?(time)
        nil
      else
        next_closing_time(time)
      end
    end

    def next_open_time(time)
      date = time.to_date
      counter = 0
      loop do
        hours = hours_on(date)
        if counter == 0 && !hours.empty?
          after = hours.select { |h| h.beginning > time.to_time_of_day || h.ending > time.to_time_of_day }
          if after.empty?
            hours = []
          else
            return date.at(after[0].beginning)
          end
        end

        if hours.empty?
          date += 1
        else
          return date.at(hours[0].beginning)
        end
        counter += 1
      end
    end

    def next_closing_time(time)
      active = hours_active(time).first
      tmp_time = active.ending_time(time)
      counter = 0
      loop do
        counter += 1; raise NoClosingError.new if counter > 1000
        found = false
        hours.each do |h|
          next if h == active
          if h.is_active?(tmp_time)
            active = h
            tmp_time = h.ending_time(tmp_time)
            found = true
          end
        end
        unless found
          return tmp_time
        end
      end
    end

    def hours_overlap?
      hours.each do |h1|
        hours.each do |h2|
          next if h1 == h2
          if h1.overlaps?(h2)
            return [h1, h2]
          end
        end
      end
      false
    end

    def week_int
      week.map do |d|
        Workhours.wday_to_int(d)
      end
    end
  end
end

