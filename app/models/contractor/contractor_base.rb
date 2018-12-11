class Contractor::ContractorBase < ActiveRecord::Base
	# https://www.thegreatcodeadventure.com/managing-multiple-databases-in-a-single-rails-application/#handlingtheconnectionpoolinabaseclass
	establish_connection :mdms
	self.abstract_class = true
end
