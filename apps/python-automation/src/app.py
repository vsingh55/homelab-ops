import os
import sys
from flask import Flask, render_template_string, request, send_file, redirect, url_for, flash

# Add src to python path to import local modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from main import process_file

app = Flask(__name__)
app.secret_key = "etap_report_generator_key"

# Configure absolute paths relative to the project root directory
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
INPUT_FOLDER = os.path.join(BASE_DIR, "data", "input")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "data", "output")

# Ensure directories exist
os.makedirs(INPUT_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Elegant, modern dark-mode upload UI
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ETAP Report Compiler</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&family=Playfair+Display:ital,wght@0,600;1,400&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: rgba(23, 31, 50, 0.7);
            --border-color: rgba(255, 255, 255, 0.08);
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
            --accent-color: #38bdf8;
            --accent-glow: rgba(56, 189, 248, 0.15);
            --success-color: #10b981;
            --error-color: #ef4444;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Outfit', sans-serif;
            background-color: var(--bg-color);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
            background-image: 
                radial-gradient(at 0% 0%, rgba(56, 189, 248, 0.05) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(16, 185, 129, 0.03) 0px, transparent 50%);
        }

        .container {
            width: 100%;
            max-width: 580px;
            background: var(--card-bg);
            backdrop-filter: blur(12px);
            border: 1px solid var(--border-color);
            border-radius: 20px;
            padding: 2.5rem;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
            transition: all 0.3s ease;
        }

        .container:hover {
            border-color: rgba(56, 189, 248, 0.25);
            box-shadow: 0 25px 50px rgba(56, 189, 248, 0.05);
        }

        header {
            text-align: center;
            margin-bottom: 2.5rem;
        }

        h1 {
            font-family: 'Playfair Display', serif;
            font-size: 2.2rem;
            font-weight: 600;
            background: linear-gradient(135deg, #f8fafc 30%, #38bdf8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.5rem;
            letter-spacing: -0.5px;
        }

        .subtitle {
            color: var(--text-secondary);
            font-size: 0.95rem;
            font-weight: 300;
        }

        .drop-zone {
            width: 100%;
            border: 2px dashed rgba(255, 255, 255, 0.15);
            border-radius: 14px;
            padding: 2.5rem 1.5rem;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s ease;
            background: rgba(255, 255, 255, 0.01);
            margin-bottom: 1.5rem;
        }

        .drop-zone:hover, .drop-zone.dragover {
            border-color: var(--accent-color);
            background: var(--accent-glow);
        }

        .drop-icon {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            color: var(--accent-color);
            transition: transform 0.2s ease;
        }

        .drop-zone:hover .drop-icon {
            transform: translateY(-4px);
        }

        .drop-zone p {
            font-size: 0.95rem;
            color: var(--text-secondary);
            margin-bottom: 0.5rem;
        }

        .file-info {
            display: none;
            margin-top: 1rem;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 0.8rem 1rem;
            align-items: center;
            justify-content: space-between;
        }

        .file-name {
            font-size: 0.9rem;
            color: var(--accent-color);
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 80%;
        }

        .btn-submit {
            display: block;
            width: 100%;
            background: var(--accent-color);
            color: #0b0f19;
            border: none;
            padding: 1rem;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow: 0 4px 12px rgba(56, 189, 248, 0.3);
            margin-top: 1.5rem;
        }

        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(56, 189, 248, 0.5);
        }

        .btn-submit:active {
            transform: translateY(0);
        }

        .samples-section {
            margin-top: 2.5rem;
            border-top: 1px solid var(--border-color);
            padding-top: 1.5rem;
        }

        .samples-section h3 {
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-secondary);
            margin-bottom: 1rem;
            font-weight: 600;
        }

        .sample-links {
            display: flex;
            gap: 1rem;
        }

        .sample-btn {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 0.8rem;
            font-size: 0.85rem;
            color: var(--text-primary);
            text-decoration: none;
            transition: all 0.2s ease;
        }

        .sample-btn:hover {
            background: rgba(255, 255, 255, 0.05);
            border-color: rgba(255, 255, 255, 0.2);
            transform: translateY(-1px);
        }

        .icon {
            margin-right: 0.5rem;
            font-size: 1.1rem;
        }

        .alert {
            padding: 1rem;
            border-radius: 10px;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
        }

        .alert-error {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: var(--error-color);
        }

        .alert-success {
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            color: var(--success-color);
        }

        footer {
            margin-top: 2rem;
            text-align: center;
            font-size: 0.8rem;
            color: var(--text-secondary);
        }
    </style>
</head>
<body>

    <div class="container">
        <header>
            <h1>Report Compiler</h1>
            <div class="subtitle">Convert ETAP spreadsheets to academic PDFs</div>
        </header>

        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert alert-{{ category }}">
                        {{ message }}
                    </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <form action="/upload" method="post" enctype="multipart/form-data">
            <div class="drop-zone" id="drop-zone" onclick="document.getElementById('file-input').click()">
                <div class="drop-icon">📤</div>
                <p>Drag & drop spreadsheet here</p>
                <p style="font-size: 0.8rem; opacity: 0.6;">Supports Excel (.xlsx) & CSV (.csv)</p>
                <input type="file" id="file-input" name="file" accept=".xlsx,.csv" style="display: none;" onchange="handleFile(this.files)">
            </div>

            <div class="file-info" id="file-info">
                <span class="file-name" id="file-name">filename.xlsx</span>
                <span style="color: var(--success-color); font-size: 0.9rem;">✓ Ready</span>
            </div>

            <button type="submit" class="btn-submit">Compile to PDF Report</button>
        </form>

        <div class="samples-section">
            <h3>Download Test Templates</h3>
            <div class="sample-links">
                <a href="/samples/sample_run_01.xlsx" class="sample-btn">
                    <span class="icon">📊</span> Excel Sheet (.xlsx)
                </a>
                <a href="/samples/sample_run_02.csv" class="sample-btn">
                    <span class="icon">📄</span> Flat CSV (.csv)
                </a>
            </div>
        </div>
    </div>

    <footer>
        Homelab Self-Hosted Portal &bull; Technical Report Compiler Service
    </footer>

    <script>
        const dropZone = document.getElementById('drop-zone');
        const fileInfo = document.getElementById('file-info');
        const fileNameSpan = document.getElementById('file-name');

        // Drag and drop handlers
        ['dragenter', 'dragover'].forEach(eventName => {
            dropZone.addEventListener(eventName, e => {
                e.preventDefault();
                dropZone.classList.add('dragover');
            }, false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, e => {
                e.preventDefault();
                dropZone.classList.remove('dragover');
            }, false);
        });

        dropZone.addEventListener('drop', e => {
            const dt = e.dataTransfer;
            const files = dt.files;
            document.getElementById('file-input').files = files;
            handleFile(files);
        });

        function handleFile(files) {
            if (files.length > 0) {
                const file = files[0];
                fileNameSpan.textContent = file.name;
                fileInfo.style.display = 'flex';
            }
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/upload', methods=['post'])
def upload():
    if 'file' not in request.files:
        flash("No file part uploaded.", "error")
        return redirect(url_for('index'))
        
    file = request.files['file']
    if file.filename == '':
        flash("No file selected.", "error")
        return redirect(url_for('index'))
        
    filename = file.filename
    ext = os.path.splitext(filename)[1].lower()
    
    if ext not in ['.xlsx', '.csv']:
        flash("Unsupported file format. Please upload an Excel (.xlsx) or CSV (.csv) file.", "error")
        return redirect(url_for('index'))
        
    # Save input file to watched inputs
    input_path = os.path.join(INPUT_FOLDER, filename)
    file.save(input_path)
    
    # Process file to PDF
    name_no_ext, _ = os.path.splitext(filename)
    output_pdf_name = f"{name_no_ext}_report.pdf"
    output_path = os.path.join(OUTPUT_FOLDER, output_pdf_name)
    
    # Run parsing & generation
    success = process_file(input_path, output_path)
    
    if success and os.path.exists(output_path):
        return send_file(
            output_path,
            as_attachment=True,
            download_name=output_pdf_name,
            mimetype='application/pdf'
        )
    else:
        flash("Failed to compile document. Please check that the data sheets comply with standard templates.", "error")
        return redirect(url_for('index'))

@app.route('/samples/<filename>')
def serve_sample(filename):
    sample_path = os.path.join(INPUT_FOLDER, filename)
    if os.path.exists(sample_path):
        return send_file(sample_path, as_attachment=True)
    else:
        return "Sample file not found.", 404

if __name__ == '__main__':
    # Default execution: run locally on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
