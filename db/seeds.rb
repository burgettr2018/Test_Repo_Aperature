# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

puts '##################'
puts 'Starting seeds.rb!'

puts 'Loading Admins..'
test1 = User.where(email:'test.admin@owenscorning.com').first_or_create!{ |u|
  u.admin = true
  u.first_name = 'Test'
  u.last_name = 'Admin'
  u.password = 'password1!'
  #u.skip_confirmation!
}
test1.update!(last_password_change_at: 1.day.ago)
puts 'Done loading admins!'

# Populate the OAuth Applications
puts 'Loading OAuth Applications...'

def create_permission_type_array(codes)
	codes.map{
			|code|
		PermissionType.new(code: code)
	}
end

def build_default_redirect_uris(prefix, localhost_port=nil)
	urls = [
			"https://#{prefix}-devel.owenscorning.com/auth/owenscorning/callback",
			"https://#{prefix}-stage.owenscorning.com/auth/owenscorning/callback",
			"https://#{prefix}.owenscorning.com/auth/owenscorning/callback",
	]
	urls << "http://localhost:#{localhost_port}/auth/owenscorning/callback" if localhost_port
	urls.join("\n")
end
default_redirect_uri = build_default_redirect_uris('login')

ums = OauthApplication.find_or_create_by!(name:'UMS') do |w|
  w.redirect_uri = default_redirect_uri
	w.permission_types = create_permission_type_array(%w(
		USERS_VIEW USERS_AUTHENTICATE USERS_MANAGE
		VIRTUAL_USERS_MANAGE CROSS_APPLICATION_PERMISSIONS
	))
	w.uid = '7cde4334d96ea4e3ef6109689e6c293da77afc2cf37d06b17849d451328602d3'
	w.secret = '4def8d6d282f0c56e99a91d8a7ba9a7254e81e4d42149bc67edcce9a4549d569'
end

oc_com = OauthApplication.find_or_create_by!(name:'OC_COM') do |w|
  w.redirect_uri = build_default_redirect_uris('mdms', 3000)
  w.application_uri = "http://localhost:3000"
	w.proper_name = 'owenscorning.com'
	w.logout_url = File.join(w.application_uri, "/users/logout")
	w.uid = 'b53dfae1493ed8309b1527b2b2e3a4183b919347b162e02674985abfa130da11'
	w.secret = '08847f74f54602abcda391cf50a6e8bf08413463c18093e8b715971ff0c52152'
end

mdms = OauthApplication.find_or_create_by!(name:'MDMS') do |w|
  w.redirect_uri = build_default_redirect_uris('mdms', 3001)
	w.application_uri = "http://localhost:3001"
	w.logout_url = File.join(w.application_uri, "/users/logout")
	w.permission_types = create_permission_type_array(%w(
		OA_ADMIN OA_SHIPTO OA_PAYER OA_SOLDTO
		PR_SHIPTO PR_PAYER PR_SOLDTO
		AD_SHIPTO AD_PAYER AD_SOLDTO
		OA_NEWSITE OA_BMG OA_CSB OA_ASM OA_IW
		CP_REGISTRATION_ASSIGNEE CP_REGISTRATION_ASSIGNEE_BUSINESS CP_REGISTRATION_ASSIGNEE_REGION
		RAILS_ADMIN BLAZER
		PRODESK_ACCESS
		DATAMART_ACCESS
		BASEMENTS_ADMIN
		PRODUCT_EDIT PRODUCT_PUBLISH
		SEND_EMAIL_SET_FROM SEND_EMAIL
		CLAIM_REVIEW CLAIM_VIEW
		DEQSNAPSHOT_AUTHENTICATE
		REQUEUE_JOBS
		CONTRACTORS_MANAGE CONTRACTORS_VIEW CONTRACTORS_FUNDS_MANAGE CONTRACTORS_WARRANTY_MANAGE
		INVOICE_ARCHIVE
		CHECK_DISBURSEMENTS
		TRUMBULL_CONTACT
		EOF_EDIT
	))
	w.uid = '2452864f51a84e30e0a1d672caeb661b545657075a7ec8b2d08d804523b24414'
	w.secret = '865cefcdcca4b4092625ac979b1bc453c8d9401599ba938153d2a788ffccf0f6'
end

lis = OauthApplication.find_or_create_by!(name:'INSTALLED-SERVICES') do |w|
  w.redirect_uri = build_default_redirect_uris('installed-services', 3000)
	w.application_uri = "http://localhost:3000"
	w.logout_url = File.join(w.application_uri, "/users/logout")
	w.permission_types = create_permission_type_array(%w(
		CONTRACTOR LOWES OC CONTRACTORS_MANAGE
	))
	w.uid = '95131c110e117a7d87704c5b5947aef4f9b2f271e1b3d3dc20402eaff61e8bc9'
	w.secret = 'c46c1357c7e503b898eff7937bf4f8aa198e42116990fedfd19ff52b69ff4b69'
end

cpi = OauthApplication.find_or_create_by!(name:'CPI') do |w|
  w.redirect_uri = build_default_redirect_uris('cpi', 3000)
	w.application_uri = "http://localhost:3000"
	w.logout_url = File.join(w.application_uri, "/users/logout")
	w.permission_types = create_permission_type_array(%w(
		INVOICE_CREATE CPI_PROCESSOR CPI_ARCHIVE
	))
	w.uid = '4461965fc5c8e78ddf39c16ffbabee3309f12542042112b2dea6b7399a155acd'
	w.secret = 'e87905da5f63c749207072f1a13327edc0e5c3354f5b48815ef774dfa5c4c359'
end

contractor_portal = OauthApplication.find_or_create_by!(name:'CONTRACTOR_PORTAL') do |w|
	w.application_uri = "http://localhost:3000/connect"
  w.redirect_uri= """http://localhost:3000/connect/users/auth/owenscorning/callback"""
	w.invitation_expiry_days = 14
	w.saml_acs = 'https://connect-devel.owenscorning.com/signin-saml2'
	w.saml_issuer = 'https://connect-devel.owenscorning.com/'
	w.saml_logout_url = 'https://connect-devel.owenscorning.com/signin-saml2'
	w.invitation_delay_seconds = 60
	w.proper_name = 'OCConnect Resource Center'
	w.logout_url = File.join(w.application_uri, "/connect/users/logout")

	w.permission_types = create_permission_type_array(%w(
		IMPERSONATE
		ACCOUNT LOCATION LEVEL ROLE
		EDIT_COMPANY_PROFILE EDIT_MARKETING_PROFILE
		USER_ADMINISTRATION
		ACCESS_MARKETING ACCESS_WARRANTIES ACCESS_LEADS ACCESS_ESTORE ACCESS_DESIGNEYEQ ACCESS_EVENTS
		SUBMIT_INVOICES
		VIEW_REWARDS REDEEM_REWARDS
		DEQ_LOCATION_DATA_OVERRIDE
	))
	w.postpone_all_invites = true
	w.uid = '441d94b6aec9b4aa1742aae2774b69c4fbe98c198d5892f9ae58bb2e196f8caa'
	w.secret = 'bdd5dc08ba5b9f96246ad5774cdc95af8773aeec2b6c04b5633cace8f7c9b80a'
end
customer_portal = OauthApplication.find_or_create_by!(name:'CUSTOMER_PORTAL') do |w|
	w.application_uri = "http://localhost:3000/customerportal"
	w.redirect_uri= """http://localhost:3000/customerportal"""
	w.invitation_expiry_days = 14
	w.invitation_delay_seconds = 180
	w.proper_name = 'Owens Corning Customer Portal'
	w.uid = 'fe0b259f68733c64db9cf3a015f7ce2ebf2802980e4f87d9e41f8a95d11c8044'
	w.secret = 'ec31918c6d17615e3264b8ec51c35dfa9f5edad091c10910a4536ce5fc225273'
end
mercury_estore = OauthApplication.find_or_create_by!(name:'MERCURY_ESTORE') do |w|
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'estore'
	w.proper_name = 'Estore'
	w.application_uri = "http://ocproconnectcontstore.com/"
	w.logout_url = ENV['UMS_RCE_ESTORE_LOGOUT_URL'].presence
end
maritz = OauthApplication.find_or_create_by!(name:'MARITZ') do |w|
	w.application_uri = "http://oe1fs.maritzstage.com/redirector/GatewayRedirectorLoginServlet"
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'cards'
	w.proper_name = 'Maritz'
end
bestroofcare = OauthApplication.find_or_create_by!(name:'BESTROOFCARE') do |w|
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'bestroofcare'
	w.application_uri = "https://www.bestroofcare.com/Contractor"
	w.proper_name = 'Best Roof Care'
end
warranty = OauthApplication.find_or_create_by!(name:'WARRANTY') do |w|
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'warranty'
	w.application_uri = "https://warranty.owenscorning.com/"
	w.proper_name = 'Warranty Management'
	w.logout_url = 'https://warranty.owenscorning.com/j_spring_security_logout'
end
learning = OauthApplication.find_or_create_by!(name:'LEARNING') do |w|
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'learning'
	w.application_uri = "http://totalprotection.prosperitylms.com/"
end
lms = OauthApplication.find_or_create_by!(name:'LMS') do |w|
	w.redirect_uri = default_redirect_uri
	w.sso_token = 'lms'
	w.application_uri = "http://roofingleads.owenscorning.com"
end
translate = OauthApplication.find_or_create_by!(name:'TRANSLATE') do |w|
	w.redirect_uri = default_redirect_uri
	w.application_uri = "https://www.translate.owenscorning.com"
	w.logout_url = File.join(w.application_uri, "/users/logout")
  w.proper_name = 'Language Translation Tool'
	w.permission_types = create_permission_type_array(%w(
		TRANSLATOR DEVELOPER
	))
	w.uid = 'cb86f9a7bc39f1cba60311610ce21f49e0d74874687ca1cd4fcdbbb67e169235'
	w.secret = '981d2fd2f7134c0064dee9c85aa0a6b62b53968aedcf73c6184c50e64915881c'
end

puts 'Done loading Oauth Applications!'

puts 'Set fields on permission types'
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'UMS'}, code: 'USERS_MANAGE').first.update_columns(is_for_employees: true)
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'CONTRACTOR_PORTAL'}, code: 'IMPERSONATE').first.update_columns(is_for_employees: true)
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'CONTRACTORS_FUNDS_MANAGE').first.update_columns(is_for_employees: true, proper_name: 'OCConnect - Payment Interface')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'PRODUCT_EDIT').first.update_columns(is_for_employees: true, is_value_required: true)
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'PRODUCT_PUBLISH').first.update_columns(is_for_employees: true, is_value_required: true)
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'BLAZER').first.update_columns(is_for_employees: true, proper_name: 'Blazer Access')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'CLAIM_VIEW').first.update_columns(is_for_employees: true, proper_name: 'OCConnect - Claim View (Readonly)')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'CLAIM_REVIEW').first.update_columns(is_for_employees: true, proper_name: 'OCConnect - Claim Review')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'TRUMBULL_CONTACT').first.update_columns(proper_name: 'Trumbull Contact Maintenance')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'OA_IW').first.update_columns(is_for_employees: true, proper_name: 'CP - InterWrap')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'OA_CSB').first.update_columns(is_for_employees: true, proper_name: 'CP - Composites')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'OA_BMG').first.update_columns(is_for_employees: true, proper_name: 'CP - BMG')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'OA_ADMIN').first.update_columns(is_for_employees: true, proper_name: 'CP - Admin')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'MDMS'}, code: 'EOF_EDIT').first.update_columns(is_for_employees: true, proper_name: 'EOF Edit')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'CPI'}, code: 'CPI_ARCHIVE').first.update_columns(is_for_employees: true, proper_name: 'View Archive')
PermissionType.joins(:oauth_application).where(oauth_applications: {name: 'CPI'}, code: 'CPI_PROCESSOR').first.update_columns(is_for_employees: true, proper_name: 'Invoice Processor')
puts 'Done with that!'


puts 'Loading API tokens'
token = ApiToken.create!(application: maritz,
								 				 expires_at: 10.years.from_now,
												 user: test1,
												 note: 'initial seed')
token.access_token.update!(token: '17136bbd901c08b3abc8fcc327f0e60b0d7f0f066707b3a0a900621ed9a96b37')

token = ApiToken.create!(application: contractor_portal,
												 expires_at: 10.years.from_now,
												 user: test1,
												 note: 'initial seed')
token.access_token.update!(token: '3bba8f519528eaf906947dda1223512f6a035f3558c5d300e18329e5d9c710e4')

token = ApiToken.create!(application: warranty,
												 expires_at: 10.years.from_now,
												 user: test1,
												 note: 'initial seed')
token.access_token.update!(token: 'd7d88c42472e1e30dfdaf8f18536a145a988f41ecbf6ee25989a85f325b93197')
puts 'Done loading API tokens'


puts 'Loading SSO redirects...'
map = {
		cart: '/oc/UserContentShoppingCart.aspx',
		prepaid_warranties: "#{contractor_portal.application_uri}/warranties/prepaid",
		warranty_sales_tools: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D44',
		digital_library: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D6',
		business_services: "#{contractor_portal.application_uri}/business-services",
		recruitment: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D579',
		ads: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D18',
		billboards: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D561',
		direct_mail: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D18',
		door_hangers: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D561',
		event_signs: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D19',
		folders: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D26',
		jobsite_signs: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D25',
		posters: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D27',
		stationary: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D28',
		storm: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D528',
		truck_graphics: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D30',
		other: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D101',
		devonshire: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D523',
		oakridge: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D495',
		duration: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D398',
		designer: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D402',
		duration_storm: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D422',
		design_inspire: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D560',
		made_in: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D575',
		program_materials: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D103',
		surenail: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D554',
		insul_ads: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D292',
		insul_brochure: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D293',
		insul_campaign: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D294',
		insul_direct_mail: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D296',
		insul_door_hanger: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D299',
		insul_promotional: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D301',
		insul_site_signs: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D303',
		insul_truck_graphics: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D306',
		insul_atticat_mkt: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D308',
		insul_general: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D313',
		in_home_selling: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D45',
		branded_merchandise: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D37',
		displays: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D48',
		literature: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D83',
		samples: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D323',
		warranty_sales: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D44',
		duration_designer: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D402',
		insul_atticat_lit: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D106',
		insul_accessories: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D336',
		insul_warranty: '/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D319',
		storm_materials:	'/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3Fcategory%3D92',
}
map.each do |k,v|
	SsoRedirect.create!(application: mercury_estore, token: k, path: v)
end
puts 'Done loading SSO redirects'

# Populate the Application Permissions
puts 'Loading Application Permissions...'

def assign_permissions(object, permissions)
	permissions.each{
			|hash_or_string|
		if Hash === hash_or_string
			application = hash_or_string[:application].present? ? OauthApplication.find_by_name(hash_or_string[:application]) : nil
			code = hash_or_string[:code]
			value = hash_or_string[:value] || '*'
		else
			application = nil
			code = hash_or_string
			value = '*'
		end
		permission_types = PermissionType.where(code: code)
		permission_types = permission_types.where(oauth_application: application) if application
		raise "Can't uniquely identify #{code}, please specify an 'application' in your assignment" if permission_types.count != 1
		object.kind_of?(OauthApplication) ?
			ApplicationPermission.create!(oauth_application: object, permission_type: permission_types.first, value: value) :
			UserPermission.create!(user: object, permission_type: permission_types.first, value: value)
	}
end

assign_permissions(lis, %w(USERS_VIEW))
assign_permissions(cpi, %w(USERS_VIEW))
assign_permissions(oc_com, %w(CROSS_APPLICATION_PERMISSIONS PRODESK_ACCESS SEND_EMAIL USERS_VIEW))
assign_permissions(oc_com, [code: 'USERS_MANAGE', application: 'UMS'])
assign_permissions(mdms, %w(USERS_AUTHENTICATE CROSS_APPLICATION_PERMISSIONS VIRTUAL_USERS_MANAGE))
assign_permissions(mdms, [code: 'USERS_MANAGE', application: 'UMS'])
assign_permissions(ums, [code: 'CONTRACTORS_MANAGE', application: 'MDMS'])
assign_permissions(ums, %w(REQUEUE_JOBS SEND_EMAIL SEND_EMAIL_SET_FROM DEQSNAPSHOT_AUTHENTICATE))
assign_permissions(mercury_estore, %w(CONTRACTORS_FUNDS_MANAGE))
assign_permissions(maritz, %w(CONTRACTORS_FUNDS_MANAGE CONTRACTORS_VIEW))
assign_permissions(contractor_portal, [code: 'CONTRACTORS_MANAGE', application: 'MDMS'])
assign_permissions(contractor_portal, [code: 'USERS_MANAGE', application: 'UMS'])
assign_permissions(contractor_portal, %w(INVOICE_ARCHIVE CHECK_DISBURSEMENTS))
assign_permissions(warranty, [code: 'CONTRACTORS_WARRANTY_MANAGE', application: 'MDMS'])

puts 'Done loading Application Permissions!'

# Populate Admin Permissions
puts 'Setting Admin Permissions...'

assign_permissions(test1, %w(
	OC PRODUCT_EDIT PRODUCT_PUBLISH RAILS_ADMIN CPI_ARCHIVE IMPERSONATE
	CONTRACTORS_FUNDS_MANAGE BLAZER CLAIM_REVIEW TRUMBULL_CONTACT OA_ADMIN EOF_EDIT
))
assign_permissions(test1, [code: 'USERS_MANAGE', application: 'UMS'])

puts 'Done setting Admin Permissions!'

puts 'Loading Contractor Portal Users..'
# want same data as dev so we can SSO into dev dynamics portal or auth against dev for local mdms accounts
# still keeping kax since we're used to him...might get rid of these accounts if we get used to others...
kax = User.where(email:'jbuff@ecuityedge.com').first_or_create!{ |u|
	u.first_name = 'Kax'
	u.last_name = 'Furman'
	u.username = 'kax'
	u.password = 'ee2017!!'
	u.guid = 'c1924898-9fd7-454f-99d4-5a80dc793d5d'
	u.last_sign_in_at = 1.day.ago
}
kax.update!(last_password_change_at: 1.day.ago)

assign_permissions(kax, [code: 'ACCOUNT', value: '50e24fc5-9ba8-e711-8117-5065f38a2b61'])
assign_permissions(kax, [code: 'LOCATION', value: '03b3e88b-d50c-e811-8126-5065f38ac921'])
assign_permissions(kax, [code: 'LEVEL', value: 'Global'])
assign_permissions(kax, [code: 'ROLE', value: 'Company Owner'])
assign_permissions(kax, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(kax, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(kax, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(kax, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(kax, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(kax, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(kax, [code: 'REDEEM_REWARDS', value: 'True'])

UserApplication.create!(user: kax, oauth_application: contractor_portal, external_id: '0944a12c-caaa-e711-811c-5065f38a7bc1', invitation_status: 'complete', application_data: {
		default_location: '03b3e88b-d50c-e811-8126-5065f38ac921',
		suffix: 'Jr',
		default_location_id: '6832627'
})

#rewards
stanlee = User.where(email:'stanlee@oc.com').first_or_create!{ |u|
	u.first_name = 'Stan'
	u.last_name = 'Lee'
	u.username = 'stanlee'
	u.password = 'Panther$17'
	u.guid = '86d117a3-e586-4b98-805c-5e6dab31120f'
	u.last_sign_in_at = 1.day.ago
}
stanlee.update!(last_password_change_at: 1.day.ago)

assign_permissions(stanlee, [code: 'ACCOUNT', value: '60f7b681-4be8-e811-815a-5065f38a7bc1'])
assign_permissions(stanlee, [code: 'LOCATION', value: 'a019a27b-4be8-e811-815a-5065f38a7bc1'])
assign_permissions(stanlee, [code: 'LEVEL', value: 'Global'])
assign_permissions(stanlee, [code: 'ROLE', value: 'Company Owner'])
assign_permissions(stanlee, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(stanlee, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(stanlee, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(stanlee, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(stanlee, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(stanlee, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(stanlee, [code: 'REDEEM_REWARDS', value: 'True'])

UserApplication.create!(user: stanlee, oauth_application: contractor_portal, external_id: '90b4f64f-4be8-e811-815a-5065f38a7bc1', invitation_status: 'complete', application_data: {
		default_location: 'a019a27b-4be8-e811-815a-5065f38a7bc1',
		default_location_id: '6832954'
})

#preferred
masterbuilder = User.where(email:'masterbuilder@oc.com').first_or_create!{ |u|
	u.first_name = 'Lloyd'
	u.last_name = 'Green'
	u.username = 'masterbuilder'
	u.password = 'Panther$17'
	u.guid = '954a490c-a950-40c9-a733-d19b99baf401'
	u.last_sign_in_at = 1.day.ago
}
masterbuilder.update!(last_password_change_at: 1.day.ago)

assign_permissions(masterbuilder, [code: 'ACCOUNT', value: 'a3c100e2-4ae8-e811-815a-5065f38a7bc1'])
assign_permissions(masterbuilder, [code: 'LOCATION', value: '2a46eedb-4ae8-e811-815a-5065f38a7bc1'])
assign_permissions(masterbuilder, [code: 'LEVEL', value: 'Global'])
assign_permissions(masterbuilder, [code: 'ROLE', value: 'Company Owner'])
assign_permissions(masterbuilder, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(masterbuilder, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(masterbuilder, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(masterbuilder, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(masterbuilder, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(masterbuilder, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(masterbuilder, [code: 'REDEEM_REWARDS', value: 'True'])

UserApplication.create!(user: masterbuilder, oauth_application: contractor_portal, external_id: '95124f8d-4ae8-e811-815a-5065f38a7bc1', invitation_status: 'complete', application_data: {
		default_location: '2a46eedb-4ae8-e811-815a-5065f38a7bc1',
		default_location_id: '6832953'
})

#platinum
townsend = User.where(email:'townsend@oc.com').first_or_create!{ |u|
	u.first_name = 'Devin'
	u.last_name = 'Garrett'
	u.username = 'townsend'
	u.password = 'Panther$17'
	u.guid = 'c5ca7604-f152-42c6-8e74-6918fadbc63f'
	u.last_sign_in_at = 1.day.ago
}
townsend.update!(last_password_change_at: 1.day.ago)

assign_permissions(townsend, [code: 'ACCOUNT', value: '9651a95e-a0e6-e811-8159-5065f38a7bc1'])
assign_permissions(townsend, [code: 'LOCATION', value: '6d51a95e-a0e6-e811-8159-5065f38a7bc1'])
assign_permissions(townsend, [code: 'LEVEL', value: 'Global'])
assign_permissions(townsend, [code: 'ROLE', value: 'Company Owner'])
assign_permissions(townsend, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(townsend, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(townsend, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(townsend, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(townsend, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(townsend, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(townsend, [code: 'REDEEM_REWARDS', value: 'True'])

UserApplication.create!(user: townsend, oauth_application: contractor_portal, external_id: '9bb79f8e-9fe6-e811-8159-5065f38a7bc1', invitation_status: 'complete', application_data: {
		default_location: '6d51a95e-a0e6-e811-8159-5065f38a7bc1',
		default_location_id: '6832951'
})

frosty = User.where(email:'frosty@snowman.com').first_or_create!{ |u|
	u.first_name = 'Frosty'
	u.last_name = 'Snowman'
	u.username = 'frosty'
	u.password = 'ee2017!!'
	u.guid = 'ac0876e9-c8bd-450b-b757-a5e98ed9e328'
	u.last_sign_in_at = 1.day.ago
}
frosty.update!(last_password_change_at: 1.day.ago)

assign_permissions(frosty, [code: 'ACCOUNT', value: '50e24fc5-9ba8-e711-8117-5065f38a2b61'])
assign_permissions(frosty, [code: 'LOCATION', value: 'ce8a25bf-9ba8-e711-8117-5065f38a2b61,03b3e88b-d50c-e811-8126-5065f38ac921'])
assign_permissions(frosty, [code: 'LEVEL', value: 'Location'])
assign_permissions(frosty, [code: 'ROLE', value: 'Administrator'])
assign_permissions(frosty, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(frosty, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(frosty, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(frosty, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(frosty, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(frosty, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(frosty, [code: 'REDEEM_REWARDS', value: 'False'])

UserApplication.create!(user: frosty, oauth_application: contractor_portal, external_id: '5da8e695-ead9-e711-9403-0004ffa2f4ed', invitation_status: 'complete', application_data: {
		default_location: '03b3e88b-d50c-e811-8126-5065f38ac921',
		suffix: 'Jr',
		default_location_id: '6832627'
})

# canadian
joetest = User.where(email:'joetest@asheroofing.com').first_or_create!{ |u|
	u.first_name = 'Joe'
	u.last_name = 'Corcoran'
	u.username = 'joetest'
	u.password = 'Panther$17'
	u.guid = '50c76d0e-cf56-4a73-8a5a-d4158f03e9a4'
	u.last_sign_in_at = 1.day.ago
}
joetest.update!(last_password_change_at: 1.day.ago)

assign_permissions(joetest, [code: 'ACCOUNT', value: '3a622aaf-7fc8-e711-811d-5065f38a2b61'])
assign_permissions(joetest, [code: 'LOCATION', value: 'df612aaf-7fc8-e711-811d-5065f38a2b61'])
assign_permissions(joetest, [code: 'LEVEL', value: 'Global'])
assign_permissions(joetest, [code: 'ROLE', value: 'Company Owner'])
assign_permissions(joetest, [code: 'VIEW_REWARDS', value: 'True'])
assign_permissions(joetest, [code: 'SUBMIT_INVOICES', value: 'True'])
assign_permissions(joetest, [code: 'USER_ADMINISTRATION', value: 'True'])
assign_permissions(joetest, [code: 'EDIT_COMPANY_PROFILE', value: 'True'])
assign_permissions(joetest, [code: 'EDIT_MARKETING_PROFILE', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_MARKETING', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_EVENTS', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_WARRANTIES', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_LEADS', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_ESTORE', value: 'True'])
assign_permissions(joetest, [code: 'ACCESS_DESIGNEYEQ', value: 'True'])
assign_permissions(joetest, [code: 'REDEEM_REWARDS', value: 'True'])

UserApplication.create!(user: joetest, oauth_application: contractor_portal, external_id: '5b47cc7d-7dc8-e711-811d-5065f38a2b61', invitation_status: 'complete', application_data: {
		default_location: 'df612aaf-7fc8-e711-811d-5065f38a2b61',
		default_location_id: '6832930'
})

puts 'Done loading Contractor Portal Users!'

puts 'Loading Customer Portal Users'

csbtestuser = User.where(email:'csbtestuser@compositesone.com').first_or_create!{ |u|
	u.first_name = 'CSB  '
	u.last_name = 'User'
	u.username = 'csbtestuser'
	u.password = 'password1!'
	u.guid = '9f49bc8c-3663-4364-aad8-cb76d0e12b8b'
	u.last_sign_in_at = 1.day.ago
}
csbtestuser.update!(last_password_change_at: 1.day.ago)

assign_permissions(csbtestuser, [code: 'OA_PAYER', value: '0001009898_10_1210,0001009898_10_1320,0001009898_41_1210,0001009898_41_1320,0001009898_17_1210,0001009898_17_1320'])
assign_permissions(csbtestuser, [code: 'PR_PAYER', value: '0001009898_10_1210,0001009898_10_1320,0001009898_41_1210,0001009898_41_1320,0001009898_17_1210,0001009898_17_1320'])
assign_permissions(csbtestuser, [code: 'PR_SOLDTO', value: '0001009898_10_1210,0001009898_10_1320,0001009898_41_1210,0001009898_41_1320,0001009898_17_1210,0001009898_17_1320'])
assign_permissions(csbtestuser, %w(OA_CSB))

puts 'Done loading Customer Portal Users!'


# these are broken, need to look into

# Populate Contractors
#Rake::Task['import_contractors:import_from_file'].invoke

# Populate Lowe's Stores
#Rake::Task['import_stores:import_from_file'].invoke

#Populate ABC Permissions
Rake::Task['import_abc_permissions:import_from_file'].invoke



puts 'Seeds.rb complete!'
puts '##################'
