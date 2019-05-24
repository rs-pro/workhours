[![Build Status](https://travis-ci.org/rs-pro/workhours.svg)](https://travis-ci.org/rs-pro/workhours)
[![Dependency Status](https://www.versioneye.com/user/projects/53e73e7635080d62b2000072/badge.svg)](https://www.versioneye.com/user/projects/53e73e7635080d62b2000072)
[![Gem version](http://img.shields.io/gem/v/workhours.svg)](http://rubygems.org/gems/workhours)
[![Issues](http://img.shields.io/github/issues/rs-pro/workhours.svg)](https://github.com/rs-pro/workhours/issues)
[![License](http://img.shields.io/:license-mit-blue.svg)](https://github.com/rs-pro/workhours/blob/master/LICENSE.txt)


# Workhours

Gem to calculate *business hours*, things like .is_open?, .is_closed?, .opens_at, .closes_at

Some code based on [business_time](https://github.com/bokmann/business_time) gem which unfortuanately handles all
configs globally and is buggy.

Uses ```tod``` gem to properly handle parsing and math with TimeOfDay (time without date).

## Installation

Add this line to your application's Gemfile:

    gem 'workhours'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install workhours

## Usage

Initialization:

    # default week - mon-fri, 9am-6pm
    week = Workhours::Week.new

    # custom hours or days
    week = Workhours::Week.new(open: '12:00', close: '20:00', week: %w(mon tue fri sat))
    week = Workhours::Week.new(holidays: [Date.parse('2014-01-01')], week: Workhours::ALL_DAYS)
    # fully custom work hours
    week = Workhours::Week.new(hours: ['mon 12:00-15:10', 'mon 15:00-16:00'])

Methods:

    week.is_open?([time])
    week.is_closed?([time])
    week.opens_at([time]) # returns nil if currently open
    week.closes_at([time]) # returns nil if currently closed

## Contributing

1. Fork it ( https://github.com/rs-pro/workhours/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
