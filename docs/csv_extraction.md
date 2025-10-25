# CSV Data Extraction Tools

This directory contains two powerful tools for extracting user-generated content from IC Metrics data into CSV format for analysis.

## Basic CSV Extractor (`bin/extract_csv`)

Extracts all contribution data into separate CSV files for each content type.

### Usage
```bash
# Extract all data for a user
ruby bin/extract_csv <username> [output_directory]

# List available users
ruby bin/extract_csv
```

### Generated Files
- `commits.csv` - All commit data with metadata
- `pull_requests.csv` - PR information and statistics  
- `reviews.csv` - Code review data
- `issues.csv` - Issues created/assigned
- `pr_comments.csv` - Comments on pull requests
- `issue_comments.csv` - Comments on issues
- `summary.csv` - Overall statistics and repository breakdown

## Advanced CSV Extractor (`bin/extract_csv_advanced`)

Provides enhanced analysis and multiple export formats.

### Usage
```bash
# Generate content analysis report
ruby bin/extract_csv_advanced analyze <username>

# Extract enhanced CSV files with analysis
ruby bin/extract_csv_advanced extract <username> [output_dir]

# Create single merged CSV with all content
ruby bin/extract_csv_advanced merge <username> [output_file]
```

### Advanced Features

#### Content Analysis (`analyze`)
- Writing pattern analysis
- Commit message categorization
- Activity distribution across repositories
- Text statistics (length, word count, etc.)

#### Enhanced Extraction (`extract`)
- `commits_enhanced.csv` - Commits with temporal analysis and message categorization
- `text_content_analysis.csv` - Detailed text analysis of all written content
- `activity_timeline.csv` - Chronological activity timeline

#### Merged Export (`merge`)
- Single CSV file containing all contribution types
- Unified format for easy analysis in tools like Excel, R, or Python
- Includes metadata and categorization

## CSV Structure Examples

### commits_enhanced.csv
```csv
repository,sha,message,message_length,message_type,author_date,day_of_week,hour,month,additions,deletions,total_changes,files_changed,conventional_commit,url
```

### text_content_analysis.csv
```csv
repository,content_type,content_id,title,body,body_length,word_count,line_count,has_code_blocks,has_links,has_mentions,created_at,url
```

### activity_timeline.csv
```csv
date,repository,type,id,title,url
```

## Analysis Use Cases

### Data Science Analysis
- Load CSV files into pandas, R, or Excel for statistical analysis
- Analyze writing patterns and communication style
- Study temporal patterns in contribution behavior
- Measure code quality metrics and commit patterns

### Performance Review
- Track contribution volume and consistency over time
- Analyze collaboration patterns through reviews and comments
- Measure code impact through additions/deletions metrics
- Review communication quality and engagement

### Team Analytics
- Compare individual contributors across the organization
- Identify expertise areas by repository contribution patterns  
- Analyze review participation and mentoring activities
- Track onboarding progress and learning curves

## File Locations

By default, CSV files are exported to:
- Basic: `data/<username>/csv_exports/`
- Advanced: `data/<username>/csv_exports/` (extract command)
- Merged: `data/<username>/all_contributions.csv` (merge command)

## Tips for Analysis

1. **Time-based Analysis**: Use the `activity_timeline.csv` for chronological studies
2. **Text Analysis**: The `text_content_analysis.csv` includes flags for code blocks, links, and mentions
3. **Commit Quality**: Enhanced commits CSV includes conventional commit classification
4. **Cross-Repository**: All CSVs include repository names for multi-repo analysis
5. **Merge Analysis**: Use the merged CSV for unified analysis across all contribution types

## Integration with Analysis Tools

### Python/Pandas
```python
import pandas as pd
df = pd.read_csv('data/username/all_contributions.csv')
df['date'] = pd.to_datetime(df['date'])
```

### R
```r
library(readr)
data <- read_csv("data/username/all_contributions.csv")
```

### Excel
Open any CSV file directly in Excel for pivot tables and charts.

The extracted CSV data provides a comprehensive foundation for quantitative analysis of developer contributions and engagement patterns.
