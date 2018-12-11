require Rails.root.join('lib', 'rails_admin', 'revoke_access_token.rb')
require Rails.root.join('lib', 'rails_admin', 'get_jwt.rb')
require Rails.root.join('lib', 'rails_admin', 'requeue_dj.rb')
require Rails.root.join('lib', 'rails_admin', 'resend_to_rce.rb')
require Rails.root.join('lib', 'rails_admin', 'resend_to_pqs.rb')
require Rails.root.join('lib', 'rails_admin', 'resend_invitation_mail.rb')
require Rails.root.join('lib', 'rails_admin', 'requeue_pi_file.rb')
require Rails.root.join('lib', 'rails_admin', 'sync_user_from_rce.rb')
require Rails.root.join('lib', 'rails_admin', 'requeue_redemption.rb')
require Rails.root.join('lib', 'rails_admin', 'requeue_member_profile_sync.rb')

RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::RevokeAccessToken)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::GetJwt)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::RequeueDj)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ResendToRce)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ResendToPqs)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::ResendInvitationMail)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::RequeuePiFile)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::SyncUserFromRce)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::RequeueRedemption)
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::RequeueMemberProfileSync)

RailsAdmin.config do |config|

  ### Popular gems integration
  config.parent_controller = '::ApplicationController'

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
    redirect_to '/' unless current_user.admin
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration



  config.actions do
    dashboard do
      statistics false
    end
    index                         # mandatory
    new do
      except ['SamlIdentityProvider', 'ApiRequestLog', 'Contractor::CheckDisbursement', 'Contractor::CheckDisbursementFile', 'Contractor::MemberProfileFundsRequest', 'Contractor::MemberProfileFundsUsage']
    end
    export do
      except %w(SamlIdentityProvider ApiToken)
    end
    bulk_delete do
      except ['SamlIdentityProvider', 'ApiRequestLog', 'Contractor::CheckDisbursement', 'Contractor::CheckDisbursementFile', 'Contractor::MemberProfileFundsRequest', 'Contractor::MemberProfileFundsUsage']
    end
    show
    edit do
			except ['MdmsJob', 'UmsJob', 'ApiRequestLog', 'Contractor::CheckDisbursement', 'Contractor::CheckDisbursementFile', 'Contractor::MemberProfileFundsRequest', 'Contractor::MemberProfileFundsUsage']
		end
    delete do
      except ['SamlIdentityProvider', 'Contractor::CheckDisbursement', 'ApiToken', 'ApiRequestLog', 'Contractor::MemberProfileFundsRequest', 'Contractor::MemberProfileFundsUsage']
    end
    revoke_access_token do
      only %w(ApiToken)
		end
		get_jwt do
			only %w(User)
		end
    requeue_dj do
      only %w(MdmsJob UmsJob)
		end
    resend_to_rce do
      only ['User', 'UserApplication']
		end
    resend_to_pqs do
      only ['Contractor::PqsProfile']
    end
    resend_invitation_mail do
      only ['User', 'UserApplication']
		end
    requeue_pi_file do
			only ['Contractor::CheckDisbursementFile']
		end
    sync_user_from_rce do
      only %w(User)
		end
    requeue_redemption do
      only ['Contractor::MemberProfileFundsUsage']
		end
    requeue_member_profile_sync do
      only ['Contractor::MemberProfile']
    end
    show_in_app

    config.default_hidden_fields[:show] = []

    config.navigation_static_links = {
        'Errbit UMS' => "https://errbit.owenscorning.com/apps/57c8809c4959b52e9200001a?environment=#{ENV['ERRBIT_ENV'] || Rails.env}",
        'Errbit MDMS' => "https://errbit.owenscorning.com/apps/57c8814c4959b52e9200002a?environment=#{ENV['ERRBIT_ENV'] || Rails.env}"
    }
    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end

#monkey patch!
require 'action_view'
module RailsAdmin
  module Config
    module Fields
      module Types
        class Datetime
          include ActionView::Helpers::DateHelper
        end
        class String
          include ActionView::Helpers::DateHelper
        end
      end
    end
  end
end

class RailsAdmin::Config::Fields::Types::Xml < RailsAdmin::Config::Fields::Types::Text
  RailsAdmin::Config::Fields::Types::register(self)
end

module Delayed
  module Backend
    module ActiveRecord
      class Job
        def retry!
          self.run_at = Time.now - 1.day
          self.locked_at = nil
          self.locked_by = nil
          self.attempts = 0
          self.last_error = nil
          self.failed_at = nil
          self.save!
        end
      end
    end
  end
end
