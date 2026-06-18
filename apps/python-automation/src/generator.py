import os
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    """
    Subclass canvas to record pages and dynamically draw 'Page X of Y' 
    running footers and running headers on all pages.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Times-Roman", 9)
        self.setFillColor(colors.HexColor('#555555'))
        self.setStrokeColor(colors.HexColor('#cccccc'))
        self.setLineWidth(0.5)
        
        # A4 margins: 54 points (0.75 inch) on left and right. 
        # Width: 595.27. Height: 841.89.
        left_margin = 54
        right_margin = 595.27 - 54
        top_y = 841.89 - 54
        bottom_y = 54
        
        # Header (Only on page 2 and later)
        if self._pageNumber > 1:
            self.line(left_margin, top_y + 10, right_margin, top_y + 10)
            self.drawString(left_margin, top_y + 16, "ETAP PARAMETER ANALYSIS REPORT")
            self.drawRightString(right_margin, top_y + 16, "TECHNICAL CONFERENCE PAPER STYLE")
            
        # Footer (On all pages)
        self.line(left_margin, bottom_y - 10, right_margin, bottom_y - 10)
        self.drawString(left_margin, bottom_y - 24, "REPORT GENERATED VIA PYTHON AUTOMATION")
        self.drawRightString(right_margin, bottom_y - 24, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def build_pdf(data_dict, line_chart_path, bar_chart_path, output_pdf_path):
    """
    Constructs the PDF document using ReportLab Platypus framework.
    """
    # Create directory if not exists
    os.makedirs(os.path.dirname(output_pdf_path), exist_ok=True)
    
    # 54pt margin corresponds to 0.75 inches
    doc = SimpleDocTemplate(
        output_pdf_path,
        pagesize=A4,
        leftMargin=54,
        rightMargin=54,
        topMargin=72,
        bottomMargin=72
    )
    
    styles = getSampleStyleSheet()
    
    # Custom Academic Styles matching Classic Academic Monochrome theme
    title_style = ParagraphStyle(
        'AcademicTitle',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.HexColor('#000000'),
        alignment=1, # Center
        spaceAfter=15
    )
    
    meta_style = ParagraphStyle(
        'AcademicMeta',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#333333'),
        alignment=1, # Center
        spaceAfter=25
    )
    
    h1_style = ParagraphStyle(
        'AcademicH1',
        parent=styles['Heading1'],
        fontName='Times-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#000000'),
        spaceBefore=15,
        spaceAfter=8,
        keepWithNext=True
    )
    
    h2_style = ParagraphStyle(
        'AcademicH2',
        parent=styles['Heading2'],
        fontName='Times-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#333333'),
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'AcademicBody',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=10.5,
        leading=15,
        textColor=colors.HexColor('#111111'),
        spaceAfter=10
    )
    
    abstract_style = ParagraphStyle(
        'AcademicAbstract',
        parent=styles['Normal'],
        fontName='Times-Italic',
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor('#222222'),
        leftIndent=20,
        rightIndent=20,
        spaceAfter=15
    )
    
    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#111111')
    )
    
    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#ffffff')
    )

    story = []
    
    # 1. Document Title
    title = data_dict['metadata'].get('title', 'Engineering Parameter Analysis Report')
    story.append(Paragraph(title.upper(), title_style))
    
    # 2. Author and Date Meta Block
    author = data_dict['metadata'].get('author', 'System Operator')
    date_str = data_dict['metadata'].get('date', '')
    meta_text = f"<b>Author:</b> {author} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Date:</b> {date_str}"
    story.append(Paragraph(meta_text, meta_style))
    
    # 3. Abstract Section
    story.append(Paragraph("<b>Abstract</b>", h2_style))
    abstract = data_dict['metadata'].get('abstract', '')
    story.append(Paragraph(abstract, abstract_style))
    
    story.append(Spacer(1, 10))
    
    # 4. Methodology
    story.append(Paragraph("1. Methodology & Data Sources", h1_style))
    methodology = data_dict['metadata'].get('methodology', '')
    story.append(Paragraph(methodology, body_style))
    
    story.append(Spacer(1, 10))
    
    # 5. Parameter Table Section
    story.append(Paragraph("2. Mathematical Parameter Limits & Measured Status", h1_style))
    
    summary_df = data_dict['summary']
    if not summary_df.empty:
        # Build table data
        table_data = []
        # Header row
        table_data.append([
            Paragraph(col, table_header_style) for col in summary_df.columns
        ])
        # Data rows
        for idx, row in summary_df.iterrows():
            row_cells = []
            for col in summary_df.columns:
                val = str(row[col])
                # Highlight status (PASS / FAIL / WARNING)
                if col.lower() == 'status':
                    if val.upper() == 'PASS':
                        cell_html = f"<font color='green'><b>{val}</b></font>"
                    elif val.upper() == 'FAIL':
                        cell_html = f"<font color='red'><b>{val}</b></font>"
                    else:
                        cell_html = f"<font color='orange'><b>{val}</b></font>"
                    row_cells.append(Paragraph(cell_html, table_cell_style))
                else:
                    row_cells.append(Paragraph(val, table_cell_style))
            table_data.append(row_cells)
            
        # Draw table
        col_count = len(summary_df.columns)
        # Allocate page widths dynamically (Total available: 595.27 - 108 = 487.27)
        # Average spacing: split columns evenly
        col_width = 487.27 / col_count
        # Tweak slightly for standard layout: first and last columns larger
        col_widths = [col_width] * col_count
        if col_count >= 5:
            # e.g. Parameter, Measured, Units, Limit, Status, Conclusion
            # Give parameter and conclusion more room
            col_widths[0] = col_width * 1.3
            col_widths[col_count - 1] = col_width * 1.7
            # shrink others
            for idx in range(1, col_count - 1):
                col_widths[idx] = col_width * 0.7
                
        summary_table = Table(table_data, colWidths=col_widths, repeatRows=1)
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#222222')),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#aaaaaa')),
            ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.HexColor('#ffffff'), colors.HexColor('#f9f9f9')]),
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('LEFTPADDING', (0,0), (-1,-1), 6),
            ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ]))
        story.append(summary_table)
    else:
        story.append(Paragraph("No parameter summary table found.", body_style))
        
    story.append(Spacer(1, 15))
    
    # 6. Visualizations Section (Using KeepTogether to prevent separation)
    viz_elements = []
    viz_elements.append(Paragraph("3. Analytical Graphical Visualizations", h1_style))
    viz_elements.append(Paragraph(
        "The plots below present (a) the runs profile of key operational parameters monitored from ETAP simulation data, "
        "and (b) a comparative analysis of the final measured parameter states against standard threshold safety limits.",
        body_style
    ))
    
    # Grid of charts
    chart_data = []
    row_charts = []
    
    if line_chart_path and os.path.exists(line_chart_path):
        row_charts.append(Image(line_chart_path, width=235, height=115))
    if bar_chart_path and os.path.exists(bar_chart_path):
        row_charts.append(Image(bar_chart_path, width=235, height=115))
        
    if len(row_charts) == 2:
        chart_data.append(row_charts)
        chart_table = Table(chart_data, colWidths=[243, 243])
        chart_table.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 0),
            ('TOPPADDING', (0,0), (-1,-1), 0),
            ('LEFTPADDING', (0,0), (-1,-1), 0),
            ('RIGHTPADDING', (0,0), (-1,-1), 0),
        ]))
        viz_elements.append(chart_table)
    else:
        # Add single columns if only one chart exists
        for chart in row_charts:
            viz_elements.append(chart)
            viz_elements.append(Spacer(1, 10))
            
    story.append(KeepTogether(viz_elements))
    
    story.append(Spacer(1, 15))
    
    # 7. Conclusions Section
    conclusion_elements = []
    conclusion_elements.append(Paragraph("4. Technical Conclusion & System Actions", h1_style))
    
    # Generate dynamic conclusion text based on warning/fail status
    warnings = 0
    failures = 0
    if not summary_df.empty and 'Status' in summary_df.columns:
        statuses = summary_df['Status'].astype(str).str.upper().tolist()
        warnings = statuses.count('WARNING')
        failures = statuses.count('FAIL')
        
    if failures > 0:
        conclusion_text = (
            f"<b>CRITICAL CRITERIA BREACH DETECTED:</b> A total of {failures} parameters have exceeded "
            "allowable operation limits (FAIL status). System shutdown or load reduction sequence should be initiated "
            "immediately. Refer to the table above to identify violating nodes."
        )
    elif warnings > 0:
        conclusion_text = (
            f"<b>WARNING STATE ACTIVE:</b> The system is operating in nominal state but {warnings} parameters "
            "are currently operating within warning zones (WARNING status). Close monitoring and preventative maintenance "
            "should be scheduled. No immediate shutdown is required."
        )
    else:
        conclusion_text = (
            "<b>NOMINAL STATE DETECTED:</b> All tested engineering and power parameters are operating well within "
            "designed safety boundaries. No anomalies or limit breaches were logged during this operational run."
        )
        
    conclusion_elements.append(Paragraph(conclusion_text, body_style))
    story.append(KeepTogether(conclusion_elements))
    
    # Compile PDF
    doc.build(story, canvasmaker=NumberedCanvas)
