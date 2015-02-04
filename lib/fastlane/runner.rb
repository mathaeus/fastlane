module Fastlane
  class Runner

    def execute(key)
      if key
        # Splits the key into two parts - lane and sublane
        lane_key_parts = key.to_s.split("__")

        lane = lane_key_parts[0].to_sym # Ex: key=test__prod, lane=test
        sublane = lane_key_parts[1].to_sym if lane_key_parts[1]  # Ex: key=test__prod, sublane=prod
      end
      key = key.to_sym

      Helper.log.info "Driving the lane '#{lane}'".green
      Actions.lane_context[Actions::SharedValues::LANE_NAME] = lane

      return_val = nil

      Dir.chdir(Fastlane::FastlaneFolder.path || Dir.pwd) do # the file is located in the fastlane folder
        @before_all.call(lane, sublane) if @before_all
        
        return_val = nil

        # Looks for most specific lane with sublane first - ex: test__prod
        if blocks[key]
          return_val = blocks[key].call sublane
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
      lane = (lane.to_s + "__" + sublane.to_s).to_sym if sublane

      raise "Lane '#{lane}' was defined multiple times!".red if blocks[lane]
      blocks[lane] = block
    end

    private
      def blocks
        @blocks ||= {}
      end
  end
end