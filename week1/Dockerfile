# Use the official Nginx base image
FROM nginx:latest

# Copy the default HTML file to the Nginx default document root
COPY index.html /usr/share/nginx/html/

# Expose port 80 for web traffic
EXPOSE 80

# Command to start Nginx when the container is run
CMD ["nginx", "-g", "daemon off;"]
