class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@owenscorning.com"
  layout 'mailer'

  def abc_no_account(user)
    @user = user
    mail(to: 'CustomerPortalSupport@owenscorning.com, GISDigitalDevelopers@Owenscorning.com', subject: "ABC Customer Portal - No Account Found")

  end

  def abc_sso_error(user,error)
    @user = user
    @error = error
    mail(to: 'GISDigitalDevelopers@Owenscorning.com', subject: "ABC Customer Portal - ERROR on SSO!!!")
  end


  def mail(headers = {}, &block)
    templates_path = headers.delete(:template_path) || self.class.mailer_name
    templates_path = Array(templates_path)
    new_templates_path = append_application_path(templates_path)

    template_name = headers.delete(:template_name)

    block = Proc.new do |format|
        begin
          if template_name.present?
            format.mjml { render template_name }
          else
            format.mjml
          end
        rescue ActionView::MissingTemplate
          if template_name.present?
            format.html { render template_name }
          else
            format.html
          end
        end
        if template_name.present?
          format.text { render template_name }
        else
          format.text
        end
    end unless block_given?
    super(headers.merge({template_path: new_templates_path}), &block)
  end

  def _prefixes
    append_application_path(super)
  end

  private
  def append_application_path(list)
    (@application.present? ? (list||[]).map{|p| File.join(@application.friendly_uid, p)} : []) + (list||[])
  end
end
