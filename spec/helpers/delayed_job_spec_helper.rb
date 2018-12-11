require "rails_helper"

module DelayedJobSpecHelper
	def perform_jobs(max=100)
		Delayed::Worker.new(quiet: false).work_off(max)
	end
	def clear_jobs
		Delayed::Job.delete_all
	end
	def job_count(method_name=nil)
		method_name ? Delayed::Job.where('handler ilike ?', "%#{method_name}%").count : Delayed::Job.count
	end
	def clear_jobs_except(method_name)
		Delayed::Job.where.not('handler ilike ?', "%#{method_name}%").delete_all
	end
end
