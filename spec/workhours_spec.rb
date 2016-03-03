require 'spec_helper'

describe 'Workhours' do
  describe 'util' do
    it 'days' do
      days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
      days.each_with_index do |d, i|
        Workhours.wday_to_int(d).should eq i
        Workhours.int_to_wday(i).should eq d
      end
    end
    it 'next_day' do
      Workhours.next_day("sun").should eq "mon"
      Workhours.next_day("mon").should eq "tue"
      Workhours.next_day("tue").should eq "wed"
      Workhours.next_day("wed").should eq "thu"
      Workhours.next_day("thu").should eq "fri"
      Workhours.next_day("fri").should eq "sat"
      Workhours.next_day("sat").should eq "sun"
    end
    it 'prev_day' do
      Workhours.prev_day("sun").should eq "sat"
      Workhours.prev_day("mon").should eq "sun"
      Workhours.prev_day("tue").should eq "mon"
      Workhours.prev_day("wed").should eq "tue"
      Workhours.prev_day("thu").should eq "wed"
      Workhours.prev_day("fri").should eq "thu"
      Workhours.prev_day("sat").should eq "fri"
    end

    describe 'period' do
      let(:period) { Workhours::Period.new(:mon, '10:00', '14:00') }
      it '#active?' do
        period.is_active?(Time.parse('2014-08-04 09:59')).should eq(false)
        period.is_active?(Time.parse('2014-08-04 10:00')).should eq(true)
        period.is_active?(Time.parse('2014-08-04 10:01')).should eq(true)
        period.is_active?(Time.parse('2014-08-04 13:59')).should eq(true)
        period.is_active?(Time.parse('2014-08-04 14:00')).should eq(true)
        period.is_active?(Time.parse('2014-08-04 14:01')).should eq(false)
        period.is_active?(Time.parse('2014-08-05 12:00')).should eq(false)
      end
    end

    describe 'day border' do
      let(:beginning) { Workhours::Period.new(:tue, '0:00', '14:00') }
      let(:ending) { Workhours::Period.new(:tue, '10:00', '0:00') }
      it '#active?' do
        beginning.is_active?(Time.parse('2014-08-04 0:00')).should eq(false)
        ending.is_active?(Time.parse('2014-08-04 0:00')).should eq(false)
        beginning.is_active?(Time.parse('2014-08-05 0:00')).should eq(true)
        ending.is_active?(Time.parse('2014-08-05 0:00')).should eq(false)
        beginning.is_active?(Time.parse('2014-08-06 0:00')).should eq(false)
        ending.is_active?(Time.parse('2014-08-06 0:00')).should eq(true)
      end
    end
  end

  describe "week" do
    describe "has defaults" do
      let(:week) { Workhours::Week.new }

      it "has default holidays" do
        week.holidays.should eq []
      end
      it "has default beginning of workday" do
        week.open.should eq '09:00'
      end
      it "has default end of workday" do
        week.close.should eq '18:00'
      end
      it "has default work week" do
        week.week.should eq %w(mon tue wed thu fri)
        week.week_int.should eq [1, 2, 3, 4, 5]
      end
      it "has default work hours" do
        week.hours.map(&:inspect).should eq  [
          "<Workhours::Period wday:mon beginning:09:00:00 ending:18:00:00>",
          "<Workhours::Period wday:tue beginning:09:00:00 ending:18:00:00>",
          "<Workhours::Period wday:wed beginning:09:00:00 ending:18:00:00>",
          "<Workhours::Period wday:thu beginning:09:00:00 ending:18:00:00>",
          "<Workhours::Period wday:fri beginning:09:00:00 ending:18:00:00>"
        ]
      end
    end

    describe "handles custom hours" do
      it 'finds overlaps' do
        week = Workhours::Week.new(hours: ['mon 12:00-15:10', 'mon 15:00-16:00'])
        week.hours_overlap?.length.should eq(2)
        week.hours_overlap?.should be_truthy
        week = Workhours::Week.new(hours: ['mon 15:00-16:00', 'mon 12:00-15:10'])
        week.hours_overlap?.length.should eq(2)
        week.hours_overlap?.should be_truthy
        week = Workhours::Week.new(hours: ['mon 15:00-16:00', 'mon 00:00-00:00'])
        week.hours_overlap?.length.should eq(2)
        week.hours_overlap?.should be_truthy
        week = Workhours::Week.new(hours: ['mon 00:00-00:00', 'mon 15:00-16:00'])
        week.hours_overlap?.length.should eq(2)
        week.hours_overlap?.should be_truthy
        week = Workhours::Week.new(hours: ['mon 00:00-00:00', 'mon 00:00-00:00'])
        week.hours_overlap?.length.should eq(2)
        week.hours_overlap?.should be_truthy

        week = Workhours::Week.new(hours: ['mon 12:00-15:00', 'mon 15:00-16:00'])
        week.hours_overlap?.should eq(false)
        week = Workhours::Week.new(hours: ['tue 15:00-16:00', 'mon 12:00-15:10'])
        week.hours_overlap?.should eq(false)
      end

      describe 'with closing time at 0:00' do
        let(:week) { Workhours::Week.new(hours: ['mon 12:00-0:00']) }
        it 'is open on monday at given hours' do
          week.is_open?(Time.parse('2014-08-04 10:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 10:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 11:59')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 12:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 12:01')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 15:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 15:01')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 16:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 16:01')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 23:59')).should eq(true)
          week.is_open?(Time.parse('2014-08-05 0:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-05 0:01')).should eq(false)
          week.is_open?(Time.parse('2014-08-05 1:01')).should eq(false)
          week.is_open?(Time.parse('2014-08-05 15:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-05 23:59')).should eq(false)
          week.is_open?(Time.parse('2014-08-06 15:30')).should eq(false)
          week.is_open?(Time.parse('2014-08-06 16:00')).should eq(false)
        end

      end

      describe 'with mon and two periods' do
        let(:week) { Workhours::Week.new(hours: ['mon 12:00-15:00', 'mon 15:00-16:00']) }

        it 'is open on monday at given hours' do
          week.is_open?(Time.parse('2014-08-04 10:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 10:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 11:59')).should eq(false)
          week.is_open?(Time.parse('2014-08-04 12:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 12:01')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 15:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 15:01')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 16:00')).should eq(true)
          week.is_open?(Time.parse('2014-08-04 16:01')).should eq(false)
          week.is_open?(Time.parse('2014-08-05 15:00')).should eq(false)
          week.is_open?(Time.parse('2014-08-06 15:30')).should eq(false)
          week.is_open?(Time.parse('2014-08-06 16:00')).should eq(false)
        end

        it 'handles default times' do
          Timecop.freeze(Time.parse('2014-08-04 10:00')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-04 10:00')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-04 11:59')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-04 12:00')) { week.is_open?.should eq(true) }
          Timecop.freeze(Time.parse('2014-08-04 12:01')) { week.is_open?.should eq(true) }
          Timecop.freeze(Time.parse('2014-08-04 15:00')) { week.is_open?.should eq(true) }
          Timecop.freeze(Time.parse('2014-08-04 15:01')) { week.is_open?.should eq(true) }
          Timecop.freeze(Time.parse('2014-08-04 16:00')) { week.is_open?.should eq(true) }
          Timecop.freeze(Time.parse('2014-08-04 16:01')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-05 13:00')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-06 15:00')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-06 15:30')) { week.is_open?.should eq(false) }
          Timecop.freeze(Time.parse('2014-08-06 16:00')) { week.is_open?.should eq(false) }
        end
      end
    end

    describe 'with holidays' do
      let(:week) { Workhours::Week.new(holidays: [Date.parse("2014-08-04")]) }
      it '#is_open?' do
        week.is_open?(Time.parse('2014-08-03 10:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 08:59')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 09:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-05 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-06 09:00')).should eq(true)
      end
    end

    describe 'with defaults' do
      let(:week) { Workhours::Week.new }
      it '#is_open?' do
        week.is_open?(Time.parse('2014-08-03 10:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 08:59')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-06 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-07 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-08 09:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-09 09:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-09 10:00')).should eq(false)
      end
      it '#opens_at' do
        week.opens_at(Time.parse('2014-08-03 10:00')).should eq(Time.parse('2014-08-04 09:00'))
        week.opens_at(Time.parse('2014-08-04 8:59')).should eq(Time.parse('2014-08-04 09:00'))
        week.opens_at(Time.parse('2014-08-04 9:00')).should be_nil
      end
      it '#closes_at' do
        week.closes_at(Time.parse('2014-08-03 10:00')).should be_nil
        week.closes_at(Time.parse('2014-08-04 08:59')).should be_nil
        week.closes_at(Time.parse('2014-08-04 09:00')).should eq(Time.parse('2014-08-04 18:00'))
        week.closes_at(Time.parse('2014-08-05 09:00')).should eq(Time.parse('2014-08-05 18:00'))
        week.closes_at(Time.parse('2014-08-06 09:00')).should eq(Time.parse('2014-08-06 18:00'))
        week.closes_at(Time.parse('2014-08-07 09:00')).should eq(Time.parse('2014-08-07 18:00'))
        week.closes_at(Time.parse('2014-08-08 09:00')).should eq(Time.parse('2014-08-08 18:00'))
        week.closes_at(Time.parse('2014-08-09 09:00')).should be_nil
        week.closes_at(Time.parse('2014-08-09 10:00')).should be_nil
      end
    end

    describe 'night shifts' do
      let(:week) { Workhours::Week.new(hours: ['mon 12:00-4:00']) }

      it '#is_open?' do
        week.is_open?(Time.parse('2014-08-03 10:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 0:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 12:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-04 12:01')).should eq(true)
        week.is_open?(Time.parse('2014-08-04 23:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 00:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 03:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 04:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 04:01')).should eq(false)
      end

      it '#opens_at' do
        week.opens_at(Time.parse('2014-08-03 10:00')).should eq(Time.parse('2014-08-04 12:00'))
        week.opens_at(Time.parse('2014-08-04 8:59')).should eq(Time.parse('2014-08-04 12:00'))
        week.opens_at(Time.parse('2014-08-04 16:00')).should be_nil
        week.opens_at(Time.parse('2014-08-04 23:00')).should be_nil
        week.opens_at(Time.parse('2014-08-05 03:00')).should be_nil
        week.opens_at(Time.parse('2014-08-05 10:00')).should eq(Time.parse('2014-08-11 12:00'))
      end
      it '#closes_at' do
        week.closes_at(Time.parse('2014-08-04 14:00')).should eq(Time.parse('2014-08-05 04:00'))
        week.closes_at(Time.parse('2014-08-05 10:00')).should be_nil
      end
    end


    describe 'whole the day' do
      let(:week) { Workhours::Week.new(hours: ['mon 00:00-00:00']) }

      it '#is_open?' do
        week.is_open?(Time.parse('2014-08-03 10:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-04 00:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-04 12:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-04 12:01')).should eq(true)
        week.is_open?(Time.parse('2014-08-04 23:00')).should eq(true)
        week.is_open?(Time.parse('2014-08-05 00:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-05 03:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-05 04:00')).should eq(false)
        week.is_open?(Time.parse('2014-08-05 04:01')).should eq(false)
      end

      it '#opens_at' do
        week.opens_at(Time.parse('2014-08-03 10:00')).should eq(Time.parse('2014-08-04 00:00'))
        week.opens_at(Time.parse('2014-08-04 00:00')).should be_nil
        week.opens_at(Time.parse('2014-08-04 16:00')).should be_nil
        week.opens_at(Time.parse('2014-08-04 23:00')).should be_nil
        week.opens_at(Time.parse('2014-08-05 00:00')).should eq(Time.parse('2014-08-11 00:00'))
        week.opens_at(Time.parse('2014-08-05 10:00')).should eq(Time.parse('2014-08-11 00:00'))
      end

      it '#closes_at' do
        week.closes_at(Time.parse('2014-08-04 14:00')).should eq(Time.parse('2014-08-05 00:00'))
        week.closes_at(Time.parse('2014-08-05 10:00')).should be_nil
      end
    end

    it 'fails with no hours' do
      expect { Workhours::Week.new(week: []) }.to raise_error(Workhours::NoHoursError)
    end
  end

  describe 'export - custom' do
    let(:week) { Workhours::Week.new(hours: ['mon 12:00-4:00']) }
    it 'export' do
      week.export.should eq({
        holidays: [],
        hours: ['mon 12:00-4:00'],
      })
    end
  end
  describe 'export - default' do
    let(:week) { Workhours::Week.new }
    it 'export' do
      week.export.should eq({
        open: '09:00',
        close: '18:00',
        holidays: [],
        week: %w(mon tue wed thu fri)
      })

    end
  end
end
