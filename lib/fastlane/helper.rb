require 'logger'


class String
  def classify
    self.split('_').collect!{ |w| w.capitalize }.join
  end
end



module Fastlane
  module Helper

    SUBLANE_DIVIDER = '__'

    # Logging happens using this method
    def self.log
      if is_test?
        @@log ||= Logger.new(nil) # don't show any logs when running tests
      else
        @@log ||= Logger.new(STDOUT)
      end

      @@log.formatter = proc do |severity, datetime, progname, msg|
        string = "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S.%2N')}]: "
        second = "#{msg}\n"

        if severity == "DEBUG"
          string = string.magenta
        elsif severity == "INFO"
          string = string.white
        elsif severity == "WARN"
          string = string.yellow
        elsif severity == "ERROR"
          string = string.red
        elsif severity == "FATAL"
          string = string.red.bold
        end


        [string, second].join("")
      end

      @@log
    end

    # @return true if the currently running program is a unit test
    def self.is_test?
      defined?SpecHelper
    end

    # @return the full path to the Xcode developer tools of the currently
    #  running system
    def self.xcode_path
      return "" if self.is_test? and not OS.mac?
      `xcode-select -p`.gsub("\n", '') + "/"
    end

    def self.gem_path
      if not Helper.is_test? and Gem::Specification::find_all_by_name('fastlane').any?
        return Gem::Specification.find_by_name('fastlane').gem_dir
      else
        return './'
      end
    end

    def self.parse_key(key)
      lane = nil
      sublane = nil

      if key
        # Replace ':' in the key with '__' cause easier to type
        key = key.to_s.gsub(':', SUBLANE_DIVIDER)

        # Splits the key into two parts - lane and sublane
        lane_key_parts = key.split(SUBLANE_DIVIDER)

        lane = lane_key_parts[0].to_sym # Ex: key=test__prod, lane=test
        sublane = lane_key_parts[1].to_sym if lane_key_parts[1]  # Ex: key=test__prod, sublane=prod
      end
      key = key.to_sym

      return lane, sublane
    end

    def self.generate_key(lane=nil, sublane = nil)
      return (lane.to_s + SUBLANE_DIVIDER + sublane.to_s).to_sym if sublane
      return lane
    end

  end
end