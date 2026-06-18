import os
import sys
import argparse
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Local modules
from parser import parse_input_file
from charts import generate_line_chart, generate_bar_chart
from generator import build_pdf

# Set up logging directories and formats
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(os.path.join("logs", "automation.log"), encoding='utf-8')
    ]
)
logger = logging.getLogger("ReportGenerator")

def process_file(input_path, output_path=None):
    """
    Processes a single Excel or CSV sheet, generates charts, builds PDF, and cleans up temp assets.
    """
    start_time = time.time()
    logger.info(f"Starting processing for file: {input_path}")
    
    if not os.path.exists(input_path):
        logger.error(f"Input file does not exist: {input_path}")
        return False
        
    try:
        # Determine defaults
        filename = os.path.basename(input_path)
        name_no_ext, _ = os.path.splitext(filename)
        
        # Temp dir for generated charts
        temp_dir = os.path.join("data", "output", "temp_charts")
        os.makedirs(temp_dir, exist_ok=True)
        
        if not output_path:
            output_path = os.path.join("data", "output", f"{name_no_ext}_report.pdf")
            
        logger.info("Parsing spreadsheet data...")
        data = parse_input_file(input_path)
        
        logger.info("Generating parameter run charts...")
        line_chart = generate_line_chart(data['time_series'], temp_dir)
        bar_chart = generate_bar_chart(data['summary'], temp_dir)
        
        logger.info(f"Compiling academic PDF report to: {output_path} ...")
        build_pdf(data, line_chart, bar_chart, output_path)
        
        # Clean up temporary charts if desired, or keep them.
        # It's better to keep them inside temp_charts or delete them to save space. Let's delete temp images.
        if line_chart and os.path.exists(line_chart):
            try:
                os.remove(line_chart)
            except:
                pass
        if bar_chart and os.path.exists(bar_chart):
            try:
                os.remove(bar_chart)
            except:
                pass
        try:
            os.rmdir(temp_dir)
        except:
            pass
            
        elapsed = time.time() - start_time
        logger.info(f"Successfully generated PDF report in {elapsed:.2f} seconds!")
        return True
        
    except Exception as e:
        logger.exception(f"Error occurred while processing file {input_path}: {str(e)}")
        return False

class SpreadsheetHandler(FileSystemEventHandler):
    """
    Watchdog event handler to capture new file creations.
    """
    def __init__(self):
        super().__init__()
        self.processed_files = set()

    def on_created(self, event):
        # We only care about files, not directories
        if event.is_directory:
            return
            
        filepath = event.src_path
        ext = os.path.splitext(filepath)[1].lower()
        
        if ext in ['.xlsx', '.csv']:
            # Skip temp excel files (~$ filename prefix)
            filename = os.path.basename(filepath)
            if filename.startswith('~$'):
                return
                
            logger.info(f"New sheet file detected: {filepath}")
            
            # Wait a brief moment to ensure file writing is fully finished
            time.sleep(1.5)
            
            # Process the file
            success = process_file(filepath)
            if success:
                self.processed_files.add(filepath)

def start_watcher(input_dir):
    """
    Starts watching the input directory for new file additions.
    """
    os.makedirs(input_dir, exist_ok=True)
    event_handler = SpreadsheetHandler()
    observer = Observer()
    observer.schedule(event_handler, path=input_dir, recursive=False)
    
    logger.info(f"Starting directory watcher on folder: '{input_dir}'")
    logger.info("Monitoring for new Excel (.xlsx) and CSV (.csv) files. Press Ctrl+C to stop...")
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Stopping watcher daemon...")
        observer.stop()
    observer.join()

def main():
    parser = argparse.ArgumentParser(description="ETAP Automated PDF Report Generator")
    parser.add_argument('-i', '--input', help="Path to input spreadsheet file (.xlsx or .csv)")
    parser.add_argument('-o', '--output', help="Path to write output PDF (optional)")
    parser.add_argument('-w', '--watch', action='store_true', help="Run in directory watcher mode")
    
    args = parser.parse_args()
    
    # Defaults
    input_watch_dir = os.path.join("data", "input")
    
    if args.watch:
        start_watcher(input_watch_dir)
    elif args.input:
        process_file(args.input, args.output)
    else:
        # If no arguments provided, display help
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
