import os
# pyrefly: ignore [missing-import]
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Set academic style for matplotlib
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.size'] = 10
plt.rcParams['axes.edgecolor'] = '#333333'
plt.rcParams['axes.linewidth'] = 0.8
plt.rcParams['xtick.color'] = '#333333'
plt.rcParams['ytick.color'] = '#333333'

def generate_line_chart(df, output_dir):
    """
    Generates a greyscale time-series line chart for parameters in time_series dataframe.
    Assumes first column is the time/run index (e.g. 'Time' or 'Run').
    """
    if df.empty or len(df.columns) < 2:
        return None
        
    os.makedirs(output_dir, exist_ok=True)
    fig, ax = plt.subplots(figsize=(6.5, 3.2), dpi=300)
    
    x_col = df.columns[0]
    x_data = df[x_col]
    
    # We will plot up to 4 other columns to avoid cluttering
    y_cols = df.columns[1:5]
    
    # Simple line styles/markers for greyscale distinction
    styles = [
        {'color': '#000000', 'linestyle': '-', 'marker': 'o'},
        {'color': '#555555', 'linestyle': '--', 'marker': 's'},
        {'color': '#888888', 'linestyle': ':', 'marker': '^'},
        {'color': '#aaaaaa', 'linestyle': '-.', 'marker': 'd'}
    ]
    
    for i, col in enumerate(y_cols):
        style = styles[i % len(styles)]
        ax.plot(x_data, df[col], label=col, **style, markersize=4, linewidth=1.2)
        
    ax.set_xlabel(str(x_col), fontsize=10, fontweight='bold', labelpad=4)
    ax.set_ylabel("Parameter Value", fontsize=10, fontweight='bold', labelpad=4)
    ax.set_title("System Parameter Run Profiles (ETAP Output)", fontsize=10, fontweight='bold', pad=8)
    
    # Minimal grid
    ax.grid(True, which='both', linestyle='--', linewidth=0.5, color='#dddddd')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    
    ax.legend(loc='upper right', frameon=True, facecolor='#ffffff', edgecolor='#cccccc', fontsize=8)
    
    fig.tight_layout()
    chart_path = os.path.join(output_dir, "run_profile_chart.png")
    fig.savefig(chart_path, dpi=300)
    plt.close(fig)
    return chart_path

def generate_bar_chart(summary_df, output_dir):
    """
    Generates a comparative bar chart comparing Measured Values against Targets/Limits.
    """
    if summary_df.empty:
        return None
        
    # Filter numeric parameters to plot
    plot_data = []
    for idx, row in summary_df.iterrows():
        param = row.get('Parameter', f"P{idx}")
        measured = row.get('Measured', None)
        limit = row.get('Limit', None)
        
        # Try converting to float
        try:
            m_val = float(measured)
            # Try to extract number from limit (e.g. '>40' -> 40, '<80' -> 80, '380-420' -> 400)
            l_str = str(limit).strip()
            l_val = None
            if l_str.startswith('>') or l_str.startswith('<'):
                l_val = float(''.join(c for c in l_str if c.isdigit() or c == '.'))
            elif '-' in l_str:
                parts = l_str.split('-')
                l_val = (float(parts[0]) + float(parts[1])) / 2.0  # use mid-point for display
            else:
                l_val = float(''.join(c for c in l_str if c.isdigit() or c == '.'))
                
            plot_data.append({
                'param': param,
                'measured': m_val,
                'limit': l_val,
                'limit_str': l_str
            })
        except:
            continue # skip non-numeric parameters for plotting
            
    if not plot_data:
        return None
        
    os.makedirs(output_dir, exist_ok=True)
    fig, ax = plt.subplots(figsize=(6.5, 3.2), dpi=300)
    
    params = [d['param'] for d in plot_data]
    measured_vals = [d['measured'] for d in plot_data]
    limit_vals = [d['limit'] for d in plot_data]
    
    x = np.arange(len(params))
    width = 0.35
    
    # Greyscale bars
    rects1 = ax.bar(x - width/2, measured_vals, width, label='Measured', color='#000000', edgecolor='#000000')
    rects2 = ax.bar(x + width/2, [l if l is not None else 0 for l in limit_vals], width, 
                    label='Limit Threshold', color='#aaaaaa', edgecolor='#555555', hatch='//')
    
    ax.set_ylabel('Value Scale', fontsize=10, fontweight='bold', labelpad=4)
    ax.set_title('Parameter Comparison: Measured vs. Safety Limit Thresholds', fontsize=10, fontweight='bold', pad=8)
    ax.set_xticks(x)
    ax.set_xticklabels(params, rotation=15, ha='right', fontsize=8)
    
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.grid(True, axis='y', which='both', linestyle='--', linewidth=0.5, color='#dddddd')
    
    ax.legend(loc='upper right', frameon=True, facecolor='#ffffff', edgecolor='#cccccc', fontsize=8)
    
    fig.tight_layout()
    chart_path = os.path.join(output_dir, "limits_comparison_chart.png")
    fig.savefig(chart_path, dpi=300)
    plt.close(fig)
    return chart_path
