FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code and scripts
COPY src/ ./src/
COPY create_samples.py .
COPY entrypoint.sh .

# Ensure entrypoint is executable
RUN chmod +x entrypoint.sh

# Create data directories and logs
RUN mkdir -p data/input data/output logs

# Expose Web Portal port
EXPOSE 5000

# Set Python Path
ENV PYTHONPATH=/app/src

# Set Entrypoint
ENTRYPOINT ["./entrypoint.sh"]

# Default command runs the Flask app
CMD ["python", "src/app.py"]
