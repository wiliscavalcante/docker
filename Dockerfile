# Use the Selenium standalone Chrome image
FROM selenium/standalone-chrome

# Switch to root to install dependencies
USER root

# Set the working directory
WORKDIR /app

# Install Python and dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3.11 python3-pip gcc libpq-dev \
    && pip install poetry \
    && poetry config virtualenvs.create false \
    && rm -rf /var/lib/apt/lists/*

# Copy only the necessary files for installing dependencies
COPY pyproject.toml poetry.lock* ./

# Install the project dependencies
RUN poetry install --no-dev --no-interaction --no-ansi

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Set the entrypoint
ENTRYPOINT ["gunicorn", "--config", "gunicorn_config.py", "app.wsgi:app"]

# Switch back to the non-root user for security
USER seluser


###############
# Use a specific tag that is maintained and updated regularly.
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /code

# Ensure the latest updates are applied to the base image and clean up afterwards to reduce image size
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# The original chmod command for /etc/resolv.conf is not included because modifying
# system files like resolv.conf is not a recommended practice for Docker images.
# If you need to customize DNS, it should be handled via the Docker run command
# or Docker Compose configuration.

# Install curl and Python poetry securely
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    curl -sSL https://install.python-poetry.org | python3 - && \
    apt-get remove -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy project files to the working directory
COPY . .

# Export poetry requirements and install them
# The --no-cache-dir flag tells pip to disable its cache, which is not needed in Docker builds
# and ensures you get the latest version of each package
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes && \
    pip install --no-cache-dir --upgrade -r requirements.txt

# Expose the port the app runs on
EXPOSE 8000

# Specify the command to run the app
ENTRYPOINT ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

