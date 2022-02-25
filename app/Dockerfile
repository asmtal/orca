# Set image to build application from
FROM python:3.8-slim-buster

# Set working directory
WORKDIR /app

# Install pipenv
RUN pip3 install pipenv

# Copy application
COPY . .

# Install dependencies
RUN pipenv install --deploy --ignore-pipfile

# Run application
CMD [ "/bin/sh", "-c" , "./run_app.sh"]
