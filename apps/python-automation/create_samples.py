import os
import pandas as pd

def create_sample_files():
    # Make directories
    os.makedirs(os.path.join("data", "input"), exist_ok=True)
    os.makedirs(os.path.join("data", "output"), exist_ok=True)
    
    # 1. Create sample_run_01.xlsx (Multi-sheet format)
    xlsx_path = os.path.join("data", "input", "sample_run_01.xlsx")
    
    metadata_data = [
        ["Title", "Power Grid Integration Performance Report"],
        ["Author", "Vijay Kumar Singh"],
        ["Date", "2026-06-18"],
        ["Abstract", "This technical report evaluates the dynamic stability and power grid integration parameters for the primary utility inverter bank. Measurements were acquired via ETAP simulation and related transient run routines under step-load conditions."],
        ["Methodology", "A 60-second operational run was conducted at a sampling interval of 10 seconds. Active power levels, system frequency, grid bus voltage, and inverter core temperature were monitored for safety limit violations."]
    ]
    metadata_df = pd.DataFrame(metadata_data)
    
    summary_data = {
        "Parameter": [
            "Active Power Output", 
            "Grid Frequency", 
            "Bus Voltage", 
            "Inverter Temperature", 
            "Total Harmonic Distortion"
        ],
        "Measured": [45.2, 50.05, 412.3, 78.4, 3.1],
        "Units": ["kW", "Hz", "V", "C", "%"],
        "Limit": [">40", "49.5-50.5", "380-420", "<80", "<5"],
        "Status": ["PASS", "PASS", "PASS", "WARNING", "PASS"],
        "Conclusion": [
            "Normal grid feed-in.",
            "Frequency stable within statutory limits.",
            "Voltage profile stable.",
            "Inverter core temperature is near warning limit.",
            "Harmonic content complies with IEEE-519."
        ]
    }
    summary_df = pd.DataFrame(summary_data)
    
    time_series_data = {
        "Time": [0, 10, 20, 30, 40, 50, 60],
        "Active Power Output": [40.1, 42.5, 44.8, 45.2, 43.9, 42.1, 40.5],
        "Grid Frequency": [50.01, 50.02, 50.04, 50.05, 50.03, 50.02, 50.01],
        "Bus Voltage": [410.2, 411.0, 411.8, 412.3, 411.5, 410.8, 410.3],
        "Inverter Temperature": [70.0, 72.5, 75.1, 78.4, 77.2, 76.0, 74.5]
    }
    time_series_df = pd.DataFrame(time_series_data)
    
    with pd.ExcelWriter(xlsx_path, engine='openpyxl') as writer:
        metadata_df.to_excel(writer, sheet_name="Metadata", index=False, header=False)
        summary_df.to_excel(writer, sheet_name="Summary", index=False)
        time_series_df.to_excel(writer, sheet_name="TimeSeries", index=False)
        
    print(f"Created sample Excel file at: {xlsx_path}")
    
    # 2. Create sample_run_02.csv (Block marked format)
    csv_path = os.path.join("data", "input", "sample_run_02.csv")
    csv_content = """[Metadata]
Title,Wind Turbine Generation Compliance Audit
Author,Vijay Kumar Singh
Date,2026-06-18
Abstract,"Performance audit report analyzing turbine grid-synchronization under variable wind shear conditions. The data runs were compiled via ETAP wind modeling adapters."
Methodology,"Transient fault-ride-through (FRT) check conducted for 60 seconds with active yawing and blade pitching enabled."

[Summary]
Parameter,Measured,Units,Limit,Status,Conclusion
Turbine Speed,14.8,rpm,<15,PASS,Rotation speed within safety threshold.
Generator Output,2.1,MW,>1.8,PASS,Generator capacity meeting baseline.
Pitch Angle,4.5,deg,0-10,PASS,Blade pitching operating nominal.
Gearbox Vibration,2.8,mm/s,<3.0,WARNING,Gearbox mechanical vibration near caution limit.
Grid Voltage,11.05,kV,10.45-11.55,PASS,Synchronization voltage compliance met.

[TimeSeries]
Time,Turbine Speed,Generator Output,Pitch Angle,Gearbox Vibration
0,12.1,1.82,2.0,2.1
10,13.5,1.95,3.1,2.3
20,14.2,2.05,4.0,2.5
30,14.8,2.10,4.5,2.8
40,14.5,2.08,4.3,2.7
50,13.9,1.98,3.8,2.6
60,12.8,1.88,2.5,2.4
"""
    with open(csv_path, "w", encoding="utf-8") as f:
        f.write(csv_content)
        
    print(f"Created sample CSV file at: {csv_path}")

if __name__ == "__main__":
    create_sample_files()
