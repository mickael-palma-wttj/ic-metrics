# frozen_string_literal: true

require 'csv'

module IcMetrics
  module Commands
    # Command to export collected data to CSV files
    class ExportCommand < BaseCommand
      def validate!
        # No strict validation - will show help if username missing
      end

      def run
        username = @args[0]
        output_dir = @args[1]

        unless username
          show_help
          return
        end

        output_dir ||= File.join(@config.data_directory, username, 'csv_exports')
        export_to_csv(username, output_dir)
      end

      private

      def show_help
        puts 'Export contribution data to CSV files'
        puts ''
        puts 'USAGE:'
        puts '  ic_metrics export <username> [output_directory]'
        puts ''
        puts 'Available users:'
        list_available_users
      end

      def list_available_users
        data_dir = @config.data_directory
        return puts "  No data found in #{data_dir}" unless Dir.exist?(data_dir)

        Dir.glob(File.join(data_dir, '*')).each do |user_dir|
          next unless File.directory?(user_dir)

          username = File.basename(user_dir)
          contributions_file = File.join(user_dir, 'contributions.json')

          puts "  #{username}" if File.exist?(contributions_file)
        end
      end

      def export_to_csv(username, output_dir)
        contributions_file = File.join(@config.data_directory, username, 'contributions.json')

        unless File.exist?(contributions_file)
          puts "Error: No contribution data found for #{username}"
          puts "Run: ic_metrics collect #{username}"
          exit 1
        end

        puts "Loading contribution data for #{username}..."
        data = JSON.parse(File.read(contributions_file))

        FileUtils.mkdir_p(output_dir)
        puts "Exporting to: #{output_dir}"

        export_commits_csv(data, output_dir)
        export_pull_requests_csv(data, output_dir)
        export_reviews_csv(data, output_dir)
        export_issues_csv(data, output_dir)
        export_pr_comments_csv(data, output_dir)
        export_issue_comments_csv(data, output_dir)
        export_summary_csv(data, output_dir)

        puts "\n✅ CSV export completed!"
        puts "Files created in: #{output_dir}"
      end

      def export_commits_csv(data, output_dir)
        csv_file = File.join(output_dir, 'commits.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository sha message author_name author_email
            author_date committer_name committer_email committer_date
            additions deletions total_changes url
          ]

          data['repositories'].each do |repo_name, repo_data|
            repo_data['commits'].each do |commit|
              commit_data = commit['commit']
              stats = commit['stats'] || {}

              csv << [
                repo_name, commit['sha'],
                commit_data['message']&.strip&.tr("\n", ' '),
                commit_data['author']['name'], commit_data['author']['email'],
                commit_data['author']['date'],
                commit_data['committer']['name'], commit_data['committer']['email'],
                commit_data['committer']['date'],
                stats['additions'] || 0, stats['deletions'] || 0,
                stats['total'] || 0, commit['html_url']
              ]
            end
          end
        end

        puts '  ✓ Commits exported to commits.csv'
      end

      def export_pull_requests_csv(data, output_dir)
        csv_file = File.join(output_dir, 'pull_requests.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository number title body state
            created_at updated_at closed_at merged_at draft
            additions deletions changed_files commits
            comments review_comments url
          ]

          data['repositories'].each do |repo_name, repo_data|
            repo_data['pull_requests'].each do |pr|
              csv << [
                repo_name, pr['number'], pr['title'],
                pr['body']&.strip&.tr("\n", ' '), pr['state'],
                pr['created_at'], pr['updated_at'], pr['closed_at'],
                pr['merged_at'], pr['draft'], pr['additions'],
                pr['deletions'], pr['changed_files'], pr['commits'],
                pr['comments'], pr['review_comments'], pr['html_url']
              ]
            end
          end
        end

        puts '  ✓ Pull requests exported to pull_requests.csv'
      end

      def export_reviews_csv(data, output_dir)
        csv_file = File.join(output_dir, 'reviews.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository review_id pull_request_number
            state body submitted_at commit_id url
          ]

          data['repositories'].each do |repo_name, repo_data|
            repo_data['reviews'].each do |review|
              csv << [
                repo_name, review['id'],
                review['pull_request_url']&.split('/')&.last,
                review['state'], review['body']&.strip&.tr("\n", ' '),
                review['submitted_at'], review['commit_id'], review['html_url']
              ]
            end
          end
        end

        puts '  ✓ Reviews exported to reviews.csv'
      end

      def export_issues_csv(data, output_dir)
        csv_file = File.join(output_dir, 'issues.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository number title body state
            created_at updated_at closed_at labels
            assignees comments_count is_pull_request url
          ]

          data['repositories'].each do |repo_name, repo_data|
            repo_data['issues'].each do |issue|
              labels = issue['labels']&.map { |l| l['name'] }&.join(';') || ''
              assignees = issue['assignees']&.map { |a| a['login'] }&.join(';') || ''

              csv << [
                repo_name, issue['number'], issue['title'],
                issue['body']&.strip&.tr("\n", ' '), issue['state'],
                issue['created_at'], issue['updated_at'], issue['closed_at'],
                labels, assignees, issue['comments'],
                issue['pull_request'] ? true : false, issue['html_url']
              ]
            end
          end
        end

        puts '  ✓ Issues exported to issues.csv'
      end

      def export_pr_comments_csv(data, output_dir)
        csv_file = File.join(output_dir, 'pr_comments.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository comment_id pull_request_number body
            created_at updated_at path position
            line commit_id url
          ]

          data['repositories'].each do |repo_name, repo_data|
            next unless repo_data['pr_comments']

            repo_data['pr_comments'].each do |comment|
              pr_number = comment['pull_request_url']&.split('/')&.last

              csv << [
                repo_name, comment['id'], pr_number,
                comment['body']&.strip&.tr("\n", ' '),
                comment['created_at'], comment['updated_at'],
                comment['path'], comment['position'], comment['line'],
                comment['commit_id'], comment['html_url']
              ]
            end
          end
        end

        puts '  ✓ PR comments exported to pr_comments.csv'
      end

      def export_issue_comments_csv(data, output_dir)
        csv_file = File.join(output_dir, 'issue_comments.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[
            repository comment_id issue_number body
            created_at updated_at url
          ]

          data['repositories'].each do |repo_name, repo_data|
            next unless repo_data['issue_comments']

            repo_data['issue_comments'].each do |comment|
              issue_number = comment['issue_url']&.split('/')&.last

              csv << [
                repo_name, comment['id'], issue_number,
                comment['body']&.strip&.tr("\n", ' '),
                comment['created_at'], comment['updated_at'],
                comment['html_url']
              ]
            end
          end
        end

        puts '  ✓ Issue comments exported to issue_comments.csv'
      end

      def export_summary_csv(data, output_dir)
        csv_file = File.join(output_dir, 'summary.csv')

        CSV.open(csv_file, 'w') do |csv|
          csv << %w[metric value]

          summary = data['summary']
          csv << ['developer', data['developer']]
          csv << ['organization', data['organization']]
          csv << ['collected_at', data['collected_at']]
          csv << ['total_commits', summary['total_commits']]
          csv << ['total_prs', summary['total_prs']]
          csv << ['total_reviews', summary['total_reviews']]
          csv << ['total_issues', summary['total_issues']]
          csv << ['total_pr_comments', summary['total_pr_comments'] || 0]
          csv << ['total_issue_comments', summary['total_issue_comments'] || 0]
          csv << ['total_repositories', data['repositories'].size]

          csv << ['', '']
          csv << %w[repository total_activity]

          data['repositories'].each do |repo_name, repo_data|
            total = repo_data['commits'].size +
                    repo_data['pull_requests'].size +
                    repo_data['reviews'].size +
                    repo_data['issues'].size +
                    (repo_data['pr_comments'] || []).size +
                    (repo_data['issue_comments'] || []).size

            csv << [repo_name, total]
          end
        end

        puts '  ✓ Summary exported to summary.csv'
      end
    end
  end
end
