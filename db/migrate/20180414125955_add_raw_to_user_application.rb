class AddRawToUserApplication < ActiveRecord::Migration
  def change
    add_column :user_applications, :invitation_token_raw, :string
    add_column :user_applications, :reminded, :boolean
    # populate raw token by finding from future scheduled expiration jobs
    UmsJob.where('handler like ?', '%invitation_expired_invitee%').each do |j|
      ua, raw = get_ua_and_raw(j)
      if ua.present?
        ua.update_columns(invitation_token_raw: raw)
      end
    end
    UmsJob.where('handler like ?', '%invitation_expired_invitee%').delete_all
    UmsJob.where('handler like ?', '%invitation_expired_inviter%').delete_all
    # populate reminded to false from remaining reminder jobs
    UmsJob.where('handler like ?', '%invitation_reminder%').each do |j|
      ua, _ = get_ua_and_raw(j)
      if ua.present?
        ua.update_columns(reminded: false)
      end
    end
    UmsJob.where('handler like ?', '%invitation_reminder%').delete_all
  end

  def get_ua_and_raw(j)
    args = j.raw_args
    if args.present? && args.size > 1
      id = args.shift
      if id == 'UserApplication'
        # old styled saved notification, first arg is a UserApplication
        id_string = args.shift
        # like this \n&nbsp;&nbsp;id:&nbsp;'14'\n&
        id = /id:&nbsp;'(\d+)'/.match(id_string)[1]
      end
      [UserApplication.where(id: id.to_i).first, args.first]
    else
      nil
    end
  end
end
