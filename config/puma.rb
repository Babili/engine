# Change to match your CPU core count
if ENV["RAILS_ENV"] == "production"
  workers 4
else
  workers 2
end

# Min and Max threads per worker
threads 1, 6


port 3000
environment ENV["RAILS_ENV"]
