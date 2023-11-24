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
