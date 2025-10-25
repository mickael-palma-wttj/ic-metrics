# IC Metrics - Developer Contribution Analysis Tool

A Ruby application to analyze developer contributions in your GitHub organization. This tool fetches commits, pull requests, reviews, and issues to provide comprehensive insights into developer activity and collaboration patterns.

## Features

- **Data Collection**: Fetch comprehensive contribution data from GitHub API
- **Local Storage**: Store all evidence locally in JSON format for analysis
- **Detailed Analysis**: Generate insights on:
  - Commit patterns and frequency
  - Pull request behavior and merge rates
  - Code review participation
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
   ```

   To create a GitHub token:
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Generate a new token with `repo` and `read:org` scopes

3. **Make the executable runnable**:
   ```bash
   chmod +x bin/ic_metrics
   ```

## Usage

### Collect Data
```bash
# Collect all contribution data for a developer
ruby bin/ic_metrics collect john.doe

# Collect data since a specific date
ruby bin/ic_metrics collect john.doe --since=2024-01-01
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
│   ├── contributions.json  # Raw contribution data
│   ├── analysis.json      # Detailed analysis results
│   └── report.md          # Human-readable report
└── jane.smith/
    ├── contributions.json
    ├── analysis.json
    └── report.md
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

- All data is stored locally in JSON format
- No data is transmitted to external services beyond GitHub API
- Raw GitHub API responses are preserved for audit trails
- Analysis can be run offline once data is collected
