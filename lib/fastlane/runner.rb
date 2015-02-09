require 'dotenv'

module Fastlane
  class Runner

    def execute(lane, sublane=nil)
      lane = lane.to_sym if lane
      sublane = sublane.to_sym if sublane

      Helper.log.info "Driving the lane '#{lane}'".green
      Actions.lane_context[Actions::SharedValues::LANE_NAME] = lane
      Actions.lane_context[Actions::SharedValues::SUBLANE_NAME] = sublane

      return_val = nil

      # Loading environment variables with dotenv
      # Note: Using "overload" since multiple lanes can be executed in a row
      if sublane
        env_file = File.join(Fastlane::FastlaneFolder.path || "", ".env.#{sublane.to_s}")
        Helper.log.info "Loading from '#{env_file}'".green
        Dotenv.overload(env_file)
      end

      Dir.chdir(Fastlane::FastlaneFolder.path || Dir.pwd) do # the file is located in the fastlane folder
        @before_all.call(lane, sublane) if @before_all
        
        return_val = nil

        # Looks for most specific lane with sublane first - ex: test__prod
        full_lane = Helper.generate_key(lane, sublane)
        if blocks[full_lane]
          return_val = blocks[full_lane].call sublane
        # Then looks for generic lane - ex: test
        elsif blocks[lane]
          return_val = blocks[lane].call
        else
          raise "Could not find lane for type '#{lane}'. Available lanes: #{available_lanes.join(', ')}".red
        end

        @after_all.call(lane, sublane) if @after_all # this is only called if no exception was raised before
      end

      return return_val
    rescue => ex
      @error.call(lane, ex) if @error # notify the block
      raise ex
    end

    def available_lanes
      blocks.keys
    end

    # Called internally
    def set_before_all(block)
      @before_all = block
    end

    def set_after_all(block)
      @after_all = block
    end

    def set_error(block)
      @error = block
    end

    def set_block(lane, sublane=nil, block)
      full_lane = Helper.generate_key(lane, sublane)

      raise "Lane '#{full_lane}' was defined multiple times!".red if blocks[full_lane]
      blocks[full_lane] = block
    end

    private
      def blocks
        @blocks ||= {}
      end
  end
end