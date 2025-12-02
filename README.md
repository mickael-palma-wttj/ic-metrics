# IC Metrics - Developer Contribution Analysis Tool

A Ruby application to analyze developer contributions in your GitHub organization. This tool fetches commits, pull requests, reviews, and issues to provide comprehensive insights into developer activity and collaboration patterns.

## Features

- **Data Collection**: Fetch comprehensive contribution data from GitHub API
  - Date range filtering with `--since` and `--until` options
  - Parallel processing for faster data retrieval
- **Local Storage**: Store all evidence locally in JSON and CSV formats
- **CSV Exports**: Export detailed data for external analysis tools
- **AI-Powered Analysis**: Integrate with Dust AI for intelligent insights
- **Full Analysis Pipeline**: One-command execution of the complete workflow
- **Detailed Analysis**: Generate insights on:
  - Commit patterns and frequency
  - Pull request behavior and merge rates
  - Code review participation (with comment bodies)
  - Issue engagement
  - Collaboration metrics
  - Productivity trends

- **Reporting**: Generate markdown reports with actionable recommendations
- **Zeitwerk Integration**: Clean, autoloaded Ruby architecture
- **Rate Limit Handling**: Respectful API usage with proper error handling

## Setup

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Configure environment variables**:
   
   **Option A: Create a .env file (recommended)**
   ```bash
   cp env.example .env
   # Edit .env with your GitHub token
   ```

   **Option B: Export environment variables**
   ```bash
   export GITHUB_TOKEN="your_github_personal_access_token"
   export GITHUB_ORG="WTTJ"  # Optional, defaults to WTTJ
   export DATA_DIRECTORY="/custom/path"  # Optional, defaults to ./data
   export DISABLE_SLEEP="true"  # Optional, disable rate limit sleep delays (use with caution)
   
   # For AI analysis (optional)
   export DUST_API_KEY="your_dust_api_key"
   export DUST_WORKSPACE_ID="your_workspace_id"
   export DUST_AGENT_ID="your_agent_id"
   ```

   To create a GitHub token:
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Generate a new token with `repo` and `read:org` scopes

3. **Make the executables runnable**:
   ```bash
   chmod +x bin/ic_metrics
   chmod +x bin/ic_metrics_full_analysis
   ```

## Usage

### Collect Data
```bash
# Collect all contribution data for a developer
ruby bin/ic_metrics collect john.doe

# Collect data since a specific date
ruby bin/ic_metrics collect john.doe --since=2024-01-01

# Collect data for a specific time period
ruby bin/ic_metrics collect john.doe --since=2024-01-01 --until=2024-06-30
```

### Export Data
```bash
# Export basic CSV files
ruby bin/ic_metrics export john.doe

# Export enhanced commits with additional metrics
ruby bin/ic_metrics export-advanced enhanced john.doe

# Export activity timeline
ruby bin/ic_metrics export-advanced timeline john.doe

# Export analysis JSON
ruby bin/ic_metrics export-advanced analysis john.doe

# Export merged CSV with all data combined
ruby bin/ic_metrics export-advanced merged john.doe
```

### AI Analysis
```bash
# Analyze CSV exports using Dust AI (requires DUST_API_KEY, DUST_WORKSPACE_ID, DUST_AGENT_ID)
ruby bin/ic_metrics analyze-csv john.doe
```

### Full Analysis Pipeline
```bash
# Run the complete analysis pipeline (collect → export → AI analysis)
./bin/ic_metrics_full_analysis john.doe

# With date range
./bin/ic_metrics_full_analysis john.doe --since=2024-01-01 --until=2024-06-30

# Short flags
./bin/ic_metrics_full_analysis john.doe -s 2024-01-01 -u 2024-06-30
```

### Analyze Data
```bash
# Analyze collected data and generate insights
ruby bin/ic_metrics analyze john.doe
```

### View Reports
```bash
# Show analysis report for a specific developer
ruby bin/ic_metrics report john.doe

# List all available reports
ruby bin/ic_metrics report
```

### Help
```bash
ruby bin/ic_metrics help
```

## Data Structure

The tool stores data in the `./data` directory:

```
data/
├── john.doe/
│   ├── contributions.json       # Raw contribution data from GitHub API
│   ├── analysis.json            # Detailed analysis results
│   ├── report.md                # Human-readable report
│   ├── activity_timeline.csv    # Chronological activity log
│   ├── all_contributions.csv    # All contributions merged
│   ├── text_content_analysis.csv # Analysis of written content
│   ├── AI_ANALYSIS_john.doe.md  # AI-generated analysis report
│   └── csv_exports/
│       ├── commits.csv          # Commit details with stats
│       ├── commits_enhanced.csv # Enhanced commit metrics
│       ├── pull_requests.csv    # PR details
│       ├── reviews.csv          # Code review details with comments
│       ├── issues.csv           # Issue details
│       ├── pr_comments.csv      # PR inline comments
│       ├── issue_comments.csv   # Issue discussion comments
│       ├── summary.csv          # Summary statistics
│       └── text_content_analysis.csv
└── jane.smith/
    └── ...
```

## Analysis Metrics

The tool provides analysis across multiple dimensions:

### Commit Analysis
- Total commits and frequency patterns
- Commit timing (hours, days of week)
- Commit message analysis
- Conventional commit compliance

### Pull Request Analysis
- PR creation and merge rates
- Average PR size and time to merge
- PR state distribution

### Review Analysis
- Code review participation
- Review response patterns
- Review state analysis

### Collaboration Metrics
- Cross-repository activity
- Unique collaborator count
- Team interaction patterns

### Productivity Metrics
- Weekly/monthly commit averages
- PR creation rates
- Repository contribution spread

## Architecture

The application uses Zeitwerk for clean autoloading and is organized into focused modules:

- `Config`: Environment and configuration management
- `GithubClient`: GitHub API interaction with rate limiting
- `DataCollector`: Orchestrates data collection across repositories
- `ContributionAnalyzer`: Generates insights and recommendations
- `CLI`: Command-line interface

## Requirements

- Ruby 3.0+
- Zeitwerk gem for autoloading
- Dotenv gem for environment variable management
- Standard library only (net/http, json, fileutils)
- GitHub personal access token with appropriate permissions

## Error Handling

The tool handles common scenarios gracefully:
- Rate limit exceeded
- Repository access denied
- Network timeouts
- Invalid GitHub tokens
- Missing data files

## Privacy and Data

- All data is stored locally in JSON and CSV formats
- AI analysis via Dust is optional (requires `DUST_API_KEY`, `DUST_WORKSPACE_ID`, `DUST_AGENT_ID`)
- Raw GitHub API responses are preserved for audit trails
- Local analysis can be run offline once data is collected
