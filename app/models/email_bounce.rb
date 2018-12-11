class EmailBounce < ActiveRecord::Base
	establish_connection :mdms

	def from
		self.data['mail']['source']
	end

	def subject
		self.data['mail']['commonHeaders']['subject']
	end

	rails_admin do
		parent User
		list do
			configure :from do

			end
			configure :subject do

			end
			include_fields :email, :from, :subject, :created_at
		end
		show do
			configure :from do

			end
			configure :subject do

			end
			include_fields :email, :from, :subject, :bounce_data, :data
		end
		export do
			configure :from do

			end
			configure :subject do

			end
			include_fields :email, :from, :subject, :created_at
		end
	end
end
