class SamlIdentityProvider < ActiveRecord::Base
	validates :name,
						:presence => true,
						:exclusion => { in: ['Database'], message: '%{value} is reserved' },
						:uniqueness => {
								:case_sensitive => false
						}
	validates :token,
						:presence => true,
						:uniqueness => {
								:case_sensitive => false
						},
						:exclusion => { in: ['database'], message: '%{value} is reserved' },
						:format => { :with => /\A^[a-zA-Z0-9_\.]*$\z/, :message => 'must contain letters, numbers, and _ or . characters only' }
	validates :issuer, presence: true
	validates :idp_sso_target_url, presence: true, url: true
	validates :idp_cert, presence: true
	validates :name_identifier_format, presence: true

	before_validation :check_blank_token
	before_validation :calculate_cert_fingerprint

	def check_blank_token
		# if blank token, then generate unique one from name
		if self.token.blank? && !self.name.blank?
			base_token = self.name.gsub(/[™®]/, '').strip.downcase.parameterize.underscore
			self.token = base_token
			i = 1
			while self.class.exists?(:token => token)
				i = i + 1
				self.token = "#{base_token}_#{i}"
			end
		end
	end

	def calculate_cert_fingerprint
		if changed.include? 'idp_cert'
			begin
				cert = OpenSSL::X509::Certificate.new(idp_cert)
				self.idp_cert_fingerprint = OpenSSL::Digest::SHA1.hexdigest(cert.to_der).scan(/../).join(':').upcase
			rescue
				errors.add :idp_cert, 'error calculating fingerprint of certificate'
				return false
			end
		end
	end

	rails_admin do
		label 'SAML Identity Provider'
		object_label_method :name

		list do
			include_fields :name, :token, :issuer, :idp_sso_target_url, :idp_cert_fingerprint, :name_identifier_format
			field :idp_sso_target_url do
				label 'IdP SSO Target URL'
			end
			field :idp_cert_fingerprint do
				label 'IdP Certificate Fingerprint'
			end
			field :name_identifier_format do
				label 'Name ID format'
			end
		end

		show do
			include_fields :name, :token, :issuer, :idp_sso_target_url, :idp_cert, :idp_cert_fingerprint, :name_identifier_format, :is_test_mode
			field :token do
				pretty_value do
					bindings[:view].render({
																		 partial: "rails_admin/main/show_saml_token",
																		 locals: {:field => self, :form => bindings[:form], variable: value}
																 }).html_safe
				end
			end
			field :idp_sso_target_url do
				label 'IdP SSO Target URL'
			end
			field :idp_cert do
				label 'IdP Certificate'
			end
			field :idp_cert_fingerprint do
				label 'IdP Certificate Fingerprint'
			end
			field :name_identifier_format do
				label 'Name ID format'
			end
		end

		edit do
			include_fields :name, :token, :issuer, :idp_sso_target_url, :idp_cert, :idp_cert_fingerprint, :name_identifier_format, :is_test_mode
			field :name do
				help 'Required. Must be unique.'
			end
			field :token do
				read_only true
				help ''
				pretty_value do
					bindings[:view].render({
																		 partial: "rails_admin/main/edit_saml_token",
																		 locals: {:field => self, :form => bindings[:form], variable: value}
																 }).html_safe
				end
			end
			field :idp_sso_target_url do
				label 'IdP SSO Target URL'
			end
			field :idp_cert, :text do
				label 'IdP Certificate'
				help 'Required.'
			end
			field :idp_cert_fingerprint do
				label 'IdP Certificate Fingerprint'
				read_only true
				help ''
			end
			field :name_identifier_format do
				label 'Name ID format'
			end
		end
	end
end
