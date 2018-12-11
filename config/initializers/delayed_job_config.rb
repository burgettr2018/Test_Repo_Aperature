Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.minutes
Delayed::Worker.read_ahead = 5
#Delayed::Worker.delay_jobs = !Rails.env.test?

require 'airbrake/delayed_job'
