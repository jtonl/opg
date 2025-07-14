FROM php:8.2-cli-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /var/www

# Copy application files
COPY public/ ./public/

# Create non-root user
RUN addgroup -g 1001 -S www && \
    adduser -S www -u 1001 -G www

# Set ownership
RUN chown -R www:www /var/www

# Switch to non-root user
USER www

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/api/status || exit 1

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]