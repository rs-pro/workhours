require "workhours/version"

require 'tod'
require 'tod/core_extensions'
require "workhours/week"
require "workhours/period"
require "workhours/util"

module Workhours
  ALL_DAYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

  extend Util

  class MultidayPeriodError < Exception;  end
  class NoHoursError < Exception;  end
  class NoClosingError < Exception;  end
end

