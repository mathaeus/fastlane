require 'dotenv'

module Fastlane
  class LaneManager
    def self.cruise_lanes(lanes)
      raise "lanes must be an array" unless lanes.kind_of?Array
      ff = Fastlane::FastFile.new(File.join(Fastlane::FastlaneFolder.path, 'Fastfile'))

      if lanes.count == 0
        raise "Please pass the name of the lane you want to drive. Available lanes: #{ff.runner.available_lanes.join(', ')}".red
      end

      # Making sure the default '.env' get loaded
      env_file = File.join(Fastlane::FastlaneFolder.path || "", '.env')
      env_default_file = File.join(Fastlane::FastlaneFolder.path || "", '.env.default')
      Dotenv.load(env_file, env_default_file)

      start = Time.now
      e = nil
      begin
        lanes.each do |key|
          lane, sublane = Helper.parse_key(key)
          ff.runner.execute(lane, sublane)
        end
      rescue => ex
        if Actions.lane_context.count > 0
          Helper.log.info "Variable Dump:".yellow
          Helper.log.info Actions.lane_context
        end
        Helper.log.fatal ex
        e = ex
      end

      # Finished with all the lanes
      Fastlane::JUnitGenerator.generate(Fastlane::Actions.executed_actions)

      duration = ((Time.now - start) / 60.0).round

      unless e
        if duration > 5
          Helper.log.info "fastlane.tools just saved you #{duration} minutes! 🎉".green
        else
          Helper.log.info "fastlane.tools finished successfully 🎉".green
        end
      else
        Helper.log.fatal "fastlane finished with errors".red
        raise e
      end
    end

  end
end