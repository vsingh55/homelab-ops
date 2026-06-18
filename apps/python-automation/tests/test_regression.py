import os
import unittest
import pandas as pd
import tempfile
import shutil

# Add src to system path for imports during testing
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from parser import parse_input_file
from charts import generate_line_chart, generate_bar_chart
from generator import build_pdf
from main import process_file

class TestReportGenerationRegression(unittest.TestCase):
    
    def setUp(self):
        # Create a temporary directory for tests
        self.test_dir = tempfile.mkdtemp()
        self.input_dir = os.path.join(self.test_dir, "input")
        self.output_dir = os.path.join(self.test_dir, "output")
        os.makedirs(self.input_dir)
        os.makedirs(self.output_dir)
        
        # Prepare sample Excel input
        self.xlsx_path = os.path.join(self.input_dir, "test_run.xlsx")
        self.create_test_excel(self.xlsx_path)
        
        # Prepare sample CSV input
        self.csv_path = os.path.join(self.input_dir, "test_run.csv")
        self.create_test_csv(self.csv_path)

    def tearDown(self):
        # Clean up all temporary test files and folders
        shutil.rmtree(self.test_dir)

    def create_test_excel(self, path):
        metadata_df = pd.DataFrame([
            ["Title", "Regression Test Report"],
            ["Author", "Tester"],
            ["Date", "2026-06-18"],
            ["Abstract", "Abstract text for regression testing."],
            ["Methodology", "Methodology description for regression testing."]
        ])
        summary_df = pd.DataFrame({
            "Parameter": ["Voltage", "Current", "Temperature"],
            "Measured": [230.1, 10.5, 45.2],
            "Units": ["V", "A", "C"],
            "Limit": ["220-240", "<16", "<60"],
            "Status": ["PASS", "PASS", "PASS"],
            "Conclusion": ["Normal", "Normal", "Normal"]
        })
        time_series_df = pd.DataFrame({
            "Time": [0, 5, 10],
            "Voltage": [230.0, 230.1, 230.1],
            "Current": [10.2, 10.4, 10.5],
            "Temperature": [40.0, 42.5, 45.2]
        })
        with pd.ExcelWriter(path, engine='openpyxl') as writer:
            metadata_df.to_excel(writer, sheet_name="Metadata", index=False, header=False)
            summary_df.to_excel(writer, sheet_name="Summary", index=False)
            time_series_df.to_excel(writer, sheet_name="TimeSeries", index=False)

    def create_test_csv(self, path):
        csv_content = """[Metadata]
Title,Regression CSV Report
Author,Tester CSV
Date,2026-06-18
Abstract,CSV Abstract.
Methodology,CSV Methodology.

[Summary]
Parameter,Measured,Units,Limit,Status,Conclusion
Pressure,1.2,bar,<2.0,PASS,Within safety range.

[TimeSeries]
Time,Pressure
0,1.0
5,1.1
10,1.2
"""
        with open(path, "w", encoding="utf-8") as f:
            f.write(csv_content)

    def test_parser_excel(self):
        data = parse_input_file(self.xlsx_path)
        self.assertEqual(data['metadata']['title'], "Regression Test Report")
        self.assertEqual(data['metadata']['author'], "Tester")
        self.assertEqual(len(data['summary']), 3)
        self.assertEqual(len(data['time_series']), 3)

    def test_parser_csv(self):
        data = parse_input_file(self.csv_path)
        self.assertEqual(data['metadata']['title'], "Regression CSV Report")
        self.assertEqual(data['metadata']['author'], "Tester CSV")
        self.assertEqual(len(data['summary']), 1)
        self.assertEqual(len(data['time_series']), 3)

    def test_chart_generation(self):
        data = parse_input_file(self.xlsx_path)
        temp_charts_dir = os.path.join(self.test_dir, "temp_charts")
        
        line_chart = generate_line_chart(data['time_series'], temp_charts_dir)
        bar_chart = generate_bar_chart(data['summary'], temp_charts_dir)
        
        self.assertIsNotNone(line_chart)
        self.assertIsNotNone(bar_chart)
        self.assertTrue(os.path.exists(line_chart))
        self.assertTrue(os.path.exists(bar_chart))

    def test_pdf_generation_flow(self):
        data = parse_input_file(self.xlsx_path)
        temp_charts_dir = os.path.join(self.test_dir, "temp_charts")
        
        line_chart = generate_line_chart(data['time_series'], temp_charts_dir)
        bar_chart = generate_bar_chart(data['summary'], temp_charts_dir)
        
        output_pdf = os.path.join(self.output_dir, "output.pdf")
        build_pdf(data, line_chart, bar_chart, output_pdf)
        
        self.assertTrue(os.path.exists(output_pdf))
        self.assertGreater(os.path.getsize(output_pdf), 0)

    def test_end_to_end_process_excel(self):
        output_pdf = os.path.join(self.output_dir, "e2e_excel.pdf")
        success = process_file(self.xlsx_path, output_pdf)
        
        self.assertTrue(success)
        self.assertTrue(os.path.exists(output_pdf))
        self.assertGreater(os.path.getsize(output_pdf), 0)

    def test_end_to_end_process_csv(self):
        output_pdf = os.path.join(self.output_dir, "e2e_csv.pdf")
        success = process_file(self.csv_path, output_pdf)
        
        self.assertTrue(success)
        self.assertTrue(os.path.exists(output_pdf))
        self.assertGreater(os.path.getsize(output_pdf), 0)

if __name__ == '__main__':
    unittest.main()
