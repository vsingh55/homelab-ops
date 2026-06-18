import os
import pandas as pd
import io

def parse_input_file(file_path):
    """
    Parses the incoming Excel (.xlsx) or CSV (.csv) file.
    Supports:
    - Multi-sheet Excel with sheets: 'Metadata', 'Summary', 'TimeSeries'
    - Single-sheet Excel or flat CSV with markers like [Metadata], [Summary], [TimeSeries]
    
    Returns a dict:
    {
        'metadata': { 'title': ..., 'author': ..., 'date': ..., 'abstract': ..., 'methodology': ... },
        'summary': pd.DataFrame,
        'time_series': pd.DataFrame
    }
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Input file not found at: {file_path}")
        
    ext = os.path.splitext(file_path)[1].lower()
    
    if ext == '.xlsx':
        try:
            # Check sheets
            with pd.ExcelFile(file_path) as xls:
                sheet_names = xls.sheet_names
                
                # Case 1: Multi-sheet Excel
                if all(s in sheet_names for s in ['Metadata', 'Summary', 'TimeSeries']):
                    metadata_df = pd.read_excel(xls, 'Metadata', header=None)
                    metadata = {}
                    for idx, row in metadata_df.iterrows():
                        if len(row) >= 2:
                            key = str(row[0]).strip().lower()
                            val = str(row[1]).strip()
                            metadata[key] = val
                    
                    summary_df = pd.read_excel(xls, 'Summary')
                    ts_df = pd.read_excel(xls, 'TimeSeries')
                    
                    return {
                        'metadata': sanitize_metadata(metadata),
                        'summary': summary_df,
                        'time_series': ts_df
                    }
        except Exception as e:
            # Fall back to single-sheet parsing if it fails
            pass
            
    # Case 2: CSV or Single-sheet Excel with block markers
    if ext == '.xlsx':
        # Load single sheet as text or data
        df = pd.read_excel(file_path, header=None)
        lines = []
        for idx, row in df.iterrows():
            line_parts = [str(val) if pd.notna(val) else "" for val in row]
            # Strip trailing empty parts
            while line_parts and line_parts[-1] == "":
                line_parts.pop()
            if line_parts:
                lines.append(",".join(line_parts))
            else:
                lines.append("")
        file_content = "\n".join(lines)
    else:
        # standard CSV text file
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            file_content = f.read()
            
    return parse_marked_sections(file_content)

def parse_marked_sections(content):
    """
    Parses a single string block containing sections marked by [Metadata], [Summary], [TimeSeries].
    """
    lines = content.split('\n')
    current_section = None
    metadata_lines = []
    summary_lines = []
    ts_lines = []
    
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.lower() == '[metadata]':
            current_section = 'metadata'
            continue
        elif stripped.lower() == '[summary]':
            current_section = 'summary'
            continue
        elif stripped.lower() == '[timeseries]':
            current_section = 'timeseries'
            continue
        
        if current_section == 'metadata':
            metadata_lines.append(line)
        elif current_section == 'summary':
            summary_lines.append(line)
        elif current_section == 'timeseries':
            ts_lines.append(line)
            
    # Parse Metadata
    metadata = {}
    for line in metadata_lines:
        # Split on first comma or colon
        if ',' in line:
            parts = line.split(',', 1)
        elif ':' in line:
            parts = line.split(':', 1)
        else:
            continue
        key = parts[0].strip().replace('"', '').replace("'", "").lower()
        val = parts[1].strip().replace('"', '').replace("'", "")
        metadata[key] = val
        
    # Parse Summary Table
    summary_df = pd.DataFrame()
    if summary_lines:
        summary_csv = "\n".join(summary_lines)
        summary_df = pd.read_csv(io.StringIO(summary_csv))
        
    # Parse TimeSeries Table
    ts_df = pd.DataFrame()
    if ts_lines:
        ts_csv = "\n".join(ts_lines)
        ts_df = pd.read_csv(io.StringIO(ts_csv))
        
    return {
        'metadata': sanitize_metadata(metadata),
        'summary': summary_df,
        'time_series': ts_df
    }

def sanitize_metadata(meta):
    """
    Ensures standard keys exist in metadata dict with fallback defaults.
    """
    standard_meta = {
        'title': meta.get('title', 'Engineering Parameter Analysis Report'),
        'author': meta.get('author', 'System Operator'),
        'date': meta.get('date', pd.Timestamp.now().strftime('%Y-%m-%d')),
        'abstract': meta.get('abstract', 'No summary provided.'),
        'methodology': meta.get('methodology', 'No methodology described.')
    }
    return standard_meta
