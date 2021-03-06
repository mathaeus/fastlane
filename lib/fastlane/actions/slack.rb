module Fastlane
  module Actions
    module SharedValues

    end

    class SlackAction
      def self.git_branch
        return nil # not working on Jenkins
        # s = `git rev-parse --abbrev-ref HEAD`
        # return s if s.to_s.length > 0
        # return nil
      end

      def self.git_author
        s = `git log --name-status HEAD^..HEAD`
        s = s.match(/Author:.*<(.*)>/)[1]
        return s if s.to_s.length > 0
        return nil
      rescue
        return nil
      end



      def self.run(params)
        options = { message: '',
                    success: true,
                    channel: nil
                  }.merge(params.first || {})

        require 'slack-notifier'

        color = (options[:success] ? 'good' : 'danger')
        options[:message] = Slack::Notifier::LinkFormatter.format(options[:message])

        url = ENV["SLACK_URL"]
        unless url
          Helper.log.fatal "Please add 'ENV[\"SLACK_URL\"] = \"https://hooks.slack.com/services/...\"' to your Fastfile's `before_all` section.".red
          raise "No SLACK_URL given.".red
        end

        notifier = Slack::Notifier.new url

        notifier.username = 'fastlane'
        if options[:channel].to_s.length > 0
          notifier.channel = options[:channel] 
          notifier.channel = ('#' + notifier.channel) unless ["#", "@"].include?notifier.channel[0] # send message to channel by default
        end

        test_result = {
          fallback: options[:message],
          text: options[:message],
          color: color,
          fields: [
            {
              title: "Lane",
              value: Actions.lane_context[Actions::SharedValues::LANE_NAME],
              short: true
            },
            {
              title: "Test Result",
              value: (options[:success] ? "Success" : "Error"),
              short: true
            }
          ]
        }

        if git_branch
          test_result[:fields] << {
            title: "Git Branch",
            value: git_branch,
            short: true
          }
        end

        if git_author
          test_result[:fields] << {
            title: "Git Author",
            value: git_author,
            short: true
          }
        end

        result = notifier.ping "",
                      icon_url: 'https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png',
                      attachments: [test_result]

        unless result.code.to_i == 200
          Helper.log.debug result
          raise "Error pushing Slack message, maybe the integration has no permission to post on this channel? Try removing the channel parameter in your Fastfile.".red
        else
          Helper.log.info "Successfully sent Slack notification".green
        end
      end
    end
  end
end
