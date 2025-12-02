# Use an official Ruby image with build tools so native gems can compile if needed.
# You can pin to a specific version for reproducibility, e.g., ruby:3.3.9
FROM ruby:3.3.5

# Create and switch to the app directory inside the image.
WORKDIR /app

# Install system packages your app/gems might need.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential=12.12 \
      git=1:2.47.3-0+deb13u1 \
      curl=8.14.1-2+deb13u2 \
      nodejs=20.19.2+dfsg-1 && \
    rm -rf /var/lib/apt/lists/*

# Add non-root user for security
RUN useradd -m appuser

# Copy gem manifests first for layer caching.
COPY Gemfile Gemfile.lock* ./

# Install Ruby gems.
RUN bundle config set path "$BUNDLE_PATH" && \
    bundle install --jobs=4 --retry=3

# Copy the rest of the app code.
COPY . .

# Remove files Dockle flags as unnecessary
RUN rm -rf .git docker-compose.yml Dockerfile

# Fix ownership for non-root user
RUN chown -R appuser:appuser /app

# Drop privileges
USER appuser

# Set environment defaults for development.
ENV RACK_ENV=development \
    RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle

# Expose the port (default 9292 for Rack/Sinatra apps).
EXPOSE 9292

# Optional healthcheck (adjust path if necessary).
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS "http://localhost:${PORT:-9292}/" || exit 1

# Default command for running the app.
CMD ["bash", "-lc", "bundle exec rackup -o 0.0.0.0 -p ${PORT:-9292}"]
