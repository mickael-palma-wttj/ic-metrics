# frozen_string_literal: true

require 'csv'
require 'date'

module IcMetrics
  module Commands
    # Advanced export command with text analysis features
    class ExportAdvancedCommand < BaseCommand
      def validate!
        # No strict validation - will show help if arguments missing
      end

      def run
        subcommand = @args[0]

        case subcommand
        when 'enhanced'
          export_enhanced(@args[1], @args[2])
        when 'timeline'
          export_timeline(@args[1], @args[2])
        when 'analysis'
          export_analysis(@args[1], @args[2])
        when 'merged'
          export_merged(@args[1], @args[2])
        else
          show_help
        end
      end

      private

      def show_help
        puts 'Advanced CSV export with text analysis'
        puts ''
        puts 'USAGE:'
        puts '  ic_metrics export-advanced <subcommand> <username> [output_path]'
        puts ''
        puts 'SUBCOMMANDS:'
        puts '  enhanced  <username> [dir]   Export with enhanced commit analysis'
        puts '  timeline  <username> [file]  Export activity timeline'
        puts '  analysis  <username> [file]  Export text content analysis'
        puts '  merged    <username> [file]  Export all data to single CSV'
        puts ''
        puts 'Available users:'
        list_available_users
      end

      def valid_username?(username)
        !username.nil? && !username.empty?
      end

      def load_data(username)
        Services::ContributionLoader.new(@config.data_directory).load(username)
      rescue Errors::DataNotFoundError
        puts "Error: No data found for #{username}"
        puts "Run: ic_metrics collect #{username}"
        exit 1
      end

      def export_enhanced(username, output_dir)
        return show_help unless valid_username?(username)

        data = load_data(username)
        output_dir ||= File.join(@config.data_directory, username, 'csv_exports')
        FileUtils.mkdir_p(output_dir)

        puts "Exporting enhanced CSV for #{username}..."

        export_commits_enhanced(data, output_dir)
        export_text_analysis(data, output_dir)

        puts "\n✅ Enhanced export completed: #{output_dir}"
      end

      def export_timeline(username, output_file)
        return show_help unless valid_username?(username)

        data = load_data(username)
        output_file ||= File.join(@config.data_directory, username, 'activity_timeline.csv')
        FileUtils.mkdir_p(File.dirname(output_file))

        puts "Generating activity timeline for #{username}..."

        activities = collect_activities(data)
        activities.sort_by! { |a| Time.parse(a[:date]) }

        CSV.open(output_file, 'w') do |csv|
          csv << %w[date repository type id title url]

          activities.each do |activity|
            csv << [
              activity[:date], activity[:repository], activity[:type],
              activity[:id], activity[:title], activity[:url]
            ]
          end
        end

        puts "✅ Timeline exported: #{output_file}"
      end

      def export_analysis(username, output_file)
        return show_help unless valid_username?(username)

        data = load_data(username)
        output_file ||= File.join(@config.data_directory, username, 'text_analysis.csv')
        FileUtils.mkdir_p(File.dirname(output_file))

        puts "Analyzing text content for #{username}..."
        export_text_analysis(data, File.dirname(output_file))

        puts "✅ Analysis exported: #{output_file}"
      end

      def export_merged(username, output_file)
        return show_help unless valid_username?(username)

        data = load_data(username)
        output_file ||= File.join(@config.data_directory, username, 'all_contributions.csv')
        FileUtils.mkdir_p(File.dirname(output_file))

        puts "Creating merged CSV for #{username}..."

        CSV.open(output_file, 'w') do |csv|
          csv << %w[
            repository type id title body date
            author state url metadata
          ]

          data['repositories'].each do |repo_name, repo_data|
            export_commits_to_merged(csv, repo_name, repo_data)
            export_prs_to_merged(csv, repo_name, repo_data)
            export_issues_to_merged(csv, repo_name, repo_data)
          end
        end

        puts "✅ Merged CSV created: #{output_file}"
      end

      def export_commits_enhanced(data, output_dir)
        CSV.open(File.join(output_dir, 'commits_enhanced.csv'), 'w') do |csv|
          csv << %w[
            repository sha message message_length message_type
            author_date day_of_week hour month
            additions deletions total_changes conventional_commit url
          ]

          data['repositories'].each do |repo_name, repo_data|
            repo_data['commits'].each do |commit|
              msg = commit['commit']['message']&.strip || ''
              date = Time.parse(commit['commit']['author']['date'])
              stats = commit['stats'] || {}

              csv << [
                repo_name, commit['sha'], msg.tr("\n", ' '),
                msg.length, Utils::CommitTypeAnalyzer.extract_type(msg),
                commit['commit']['author']['date'],
                date.strftime('%A'), date.hour, date.strftime('%B'),
                stats['additions'] || 0, stats['deletions'] || 0, stats['total'] || 0,
                Utils::CommitTypeAnalyzer.conventional_commit?(msg), commit['html_url']
              ]
            end
          end
        end

        puts '  ✓ Enhanced commits exported'
      end

      def export_text_analysis(data, output_dir)
        CSV.open(File.join(output_dir, 'text_content_analysis.csv'), 'w') do |csv|
          csv << %w[
            repository content_type content_id title body
            body_length word_count line_count
            has_code_blocks has_links has_mentions
            created_at url
          ]

          data['repositories'].each do |repo_name, repo_data|
            analyze_prs(csv, repo_name, repo_data['pull_requests'])
            analyze_issues(csv, repo_name, repo_data['issues'])
            analyze_comments(csv, repo_name, repo_data)
          end
        end

        puts '  ✓ Text analysis exported'
      end

      def collect_activities(data)
        activities = []

        data['repositories'].each do |repo_name, repo_data|
          repo_data['commits'].each do |c|
            activities << {
              repository: repo_name, type: 'commit', id: c['sha'],
              title: c['commit']['message']&.lines&.first&.strip || '',
              date: c['commit']['author']['date'], url: c['html_url']
            }
          end

          repo_data['pull_requests'].each do |pr|
            activities << {
              repository: repo_name, type: 'pull_request', id: pr['number'],
              title: pr['title'], date: pr['created_at'], url: pr['html_url']
            }
          end

          repo_data['reviews'].each do |r|
            activities << {
              repository: repo_name, type: 'review', id: r['id'],
              title: r['state'], date: r['submitted_at'], url: r['html_url']
            }
          end

          repo_data['issues'].each do |i|
            next if i['pull_request']

            activities << {
              repository: repo_name, type: 'issue', id: i['number'],
              title: i['title'], date: i['created_at'], url: i['html_url']
            }
          end
        end

        activities
      end

      def analyze_prs(csv, repo_name, prs)
        prs.each do |pr|
          body = pr['body'] || ''
          csv << [
            repo_name, 'pull_request', pr['number'], pr['title'], body,
            body.length, Utils::TextAnalyzer.word_count(body), Utils::TextAnalyzer.line_count(body),
            Utils::TextAnalyzer.has_code_blocks?(body), Utils::TextAnalyzer.has_links?(body),
            Utils::TextAnalyzer.has_mentions?(body),
            pr['created_at'], pr['html_url']
          ]
        end
      end

      def analyze_issues(csv, repo_name, issues)
        issues.each do |issue|
          next if issue['pull_request']

          body = issue['body'] || ''
          csv << [
            repo_name, 'issue', issue['number'], issue['title'], body,
            body.length, Utils::TextAnalyzer.word_count(body), Utils::TextAnalyzer.line_count(body),
            Utils::TextAnalyzer.has_code_blocks?(body), Utils::TextAnalyzer.has_links?(body),
            Utils::TextAnalyzer.has_mentions?(body),
            issue['created_at'], issue['html_url']
          ]
        end
      end

      def analyze_comments(csv, repo_name, repo_data)
        [
          [repo_data['pr_comments'] || [], 'pr_comment'],
          [repo_data['issue_comments'] || [], 'issue_comment'],
          [repo_data['reviews'] || [], 'review']
        ].each do |comments, type|
          comments.each do |comment|
            body = comment['body'] || ''
            next if body.empty?

            date_field = type == 'review' ? 'submitted_at' : 'created_at'
            csv << [
              repo_name, type, comment['id'], '', body,
              body.length, Utils::TextAnalyzer.word_count(body), Utils::TextAnalyzer.line_count(body),
              Utils::TextAnalyzer.has_code_blocks?(body), Utils::TextAnalyzer.has_links?(body),
              Utils::TextAnalyzer.has_mentions?(body),
              comment[date_field], comment['html_url']
            ]
          end
        end
      end

      def export_commits_to_merged(csv, repo_name, repo_data)
        repo_data['commits'].each do |c|
          msg = c['commit']['message']
          csv << [
            repo_name, 'commit', c['sha'], msg&.lines&.first&.strip,
            msg, c['commit']['author']['date'], c['commit']['author']['name'],
            'committed', c['html_url'],
            "changes:#{c['stats']&.dig('total') || 0}"
          ]
        end
      end

      def export_prs_to_merged(csv, repo_name, repo_data)
        repo_data['pull_requests'].each do |pr|
          csv << [
            repo_name, 'pull_request', pr['number'], pr['title'], pr['body'],
            pr['created_at'], pr['user']['login'], pr['state'], pr['html_url'],
            "additions:#{pr['additions']};deletions:#{pr['deletions']}"
          ]
        end
      end

      def export_issues_to_merged(csv, repo_name, repo_data)
        repo_data['issues'].each do |issue|
          next if issue['pull_request']

          csv << [
            repo_name, 'issue', issue['number'], issue['title'], issue['body'],
            issue['created_at'], issue['user']['login'], issue['state'],
            issue['html_url'], "comments:#{issue['comments']}"
          ]
        end
      end
    end
  end
end
