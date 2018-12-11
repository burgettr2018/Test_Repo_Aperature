module OktaCookieHelper
  def set_signed_in_with_okta_cookie
    cookies[:signed_in_with_okta] = { :value => true,:expires => 1.year.from_now}
  end

  def set_signed_in_with_oktaabc_cookie
    cookies[:signed_in_with_oktaabc] = { :value => true, :expires => 1.year.from_now}
  end

  def previously_signed_in_with_okta?
    !!cookies[:signed_in_with_okta]
  end

  def previously_signed_in_with_oktaabc?
    !!cookies[:signed_in_with_oktaabc]
  end
end
