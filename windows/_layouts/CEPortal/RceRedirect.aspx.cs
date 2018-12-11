using System;
using Microsoft.SharePoint;
using Microsoft.SharePoint.WebControls;
using Microsoft.IdentityModel.Web;
using Microsoft.SharePoint.Utilities;
using System.Web;
using System.Globalization;
using System.Collections.Generic;
using System.Security.Principal;
using System.Web.Configuration;
using Microsoft.IdentityModel.Claims;
using System.Configuration;
using System.Security.Cryptography;

namespace OwensCorning.CustomerPortal.Portal.Layouts.CEPortal
{
    public partial class RceRedirect : LayoutsPageBase
    {
        protected void RedirectToLogout()
        {
            //string emailId = Common.Common.GetEmailFromClaims(this.Page.User as IPrincipal);
            //TransactionalService.UserProfileDataObject objUserProfileDO = Common.Common.GetUserProfile(emailId);
            //String portalContentTypeUser = objUserProfileDO.PortalContentType;
            //if (portalContentTypeUser.Equals("BMG USA"))
            //{
            //    Response.Redirect(WebConfigurationManager.AppSettings["LogOutUrl"], true);
            //}
            //else if (portalContentTypeUser.Equals("BMG CANADA"))
            //{
            //    Response.Redirect(WebConfigurationManager.AppSettings["LogOutUrlCANADA"], true);
            //}
            //else
            //{
                Response.Redirect(WebConfigurationManager.AppSettings["LogOutUrl"], true);
            //}
        }
        protected void RedirectToEstore(string estoreUrl)
        {
            if (estoreUrl.StartsWith("http"))
            {
                Response.Redirect(estoreUrl, true);
            }
            else
            {
                Response.Write("<!doctype html>\r\n");
                Response.Write("<meta http-equiv=\"refresh\" content=\"0,URL=" + estoreUrl + "\">");
            }
        }
        protected void Logout()
        {
            // copied from TransactionalSignout.aspx
            String loggedinUser = String.Empty;
            if (Session["ABCLoggedInUserEmail"] != null)
            {
                loggedinUser = Session["ABCLoggedInUserEmail"].ToString();
            }

            string[] cookieNameList = new string[]
            {
                "SamlSession", "SamlLogout",
                "MSISAuth", "MSISAuth1", "MSISAuth2", "MSISAuth3", "MSISAuth4",
                "MSISAuthenticated", "MSISLoopDetectionCookie",
                "MSISSignOut", "WSFedLogout", "LogoutReturnUrl"
            };

            // Clean the cookies for the session
            foreach (string cookieName in cookieNameList)
            {
                HttpCookie cookie = new HttpCookie(cookieName, String.Empty);
                cookie.Expires = DateTime.UtcNow.AddYears(-1);
                cookie.Path = "/adfs/ls";
                Response.Cookies.Add(cookie);
            }
            //added for multilingual @kaushik 22-11-2013
            //added end @kaushik 22-11-2013
            Session.Abandon();
            Session.Clear();
            Session.RemoveAll();
            FederatedAuthentication.SessionAuthenticationModule.SignOut();
            FederatedAuthentication.SessionAuthenticationModule.DeleteSessionTokenCookie();
            FederatedAuthentication.SessionAuthenticationModule.Dispose();
            SSOAuditSave(true, loggedinUser);
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request.QueryString["action"];
            string env = Request.QueryString["env"];
            string email = Request.QueryString["email"];
            if (string.IsNullOrEmpty(action) || string.IsNullOrEmpty(env))
            {
                // if page incorrectly used, logout
                RedirectToLogout();
                return;
            }
            string estoreUrl = null;
            string baseAdUrl = null;
            string baseUmsUrl = null;
            switch (env.ToLower())
            {
                case "local":
                    estoreUrl = "https://staging.ocproconnectcontcoop.com/oc/default.aspx?SuccessUrl=UserContentStart.aspx&amp;categoryCode=proconnect_webstore";
                    baseAdUrl = "https://qaadfs.owenscorning.com/adfs/ls/";
                    baseUmsUrl = "https://pmzntvskth.localtunnel.me/";
                    break;
                case "dev":
                    estoreUrl = "data:text/plain;charset=utf-8;base64,eW91IGRpZCBpdCE=";
                    baseAdUrl = "https://portalsso.owenscorning.com/adfs/ls/";
                    baseUmsUrl = "https://login-devel.owenscorning.com/";
                    break;
                case "stage":
                    estoreUrl = "https://staging.ocproconnectcontcoop.com/oc/default.aspx?SuccessUrl=UserContentStart.aspx&amp;categoryCode=proconnect_webstore";
                    baseAdUrl = "https://qaadfs.owenscorning.com/adfs/ls/";
                    baseUmsUrl = "https://login-stage.owenscorning.com/";
                    break;
                case "prod":
                    estoreUrl = "https://ocproconnectcontcoop.com/oc/default.aspx?SuccessUrl=UserContentStart.aspx&amp;categoryCode=proconnect_webstore";
                    baseAdUrl = "https://portalsso.owenscorning.com/adfs/ls/";
                    baseUmsUrl = "https://login.owenscorning.com/";
                    break;
                default:
                    RedirectToLogout();
                    return;
            }
            // note, use "rce" so it is handled properly on receiving end
            baseAdUrl += "?wa=wsignout1.0&portal=rce&iframe=true";
            switch (action.ToLower())
            {
                case "login_estore":
                    RedirectToEstore(estoreUrl);
                    break;
                case "logout":
                    Logout();
                    Response.Redirect(baseAdUrl);
                    break;
                case "keepalive":
                    Response.AppendHeader("Access-Control-Allow-Origin", baseUmsUrl.TrimEnd('/'));
                    Response.AppendHeader("Access-Control-Allow-Methods", "GET");
                    Response.AppendHeader("Access-Control-Allow-Credentials", "true");
                    Response.End();
                    break;
                default:
                    RedirectToLogout();
                    return;
            }
        }

        #region SSO Audit
        // copied from TransactionalSignout.aspx
        public void SSOAuditSave(Boolean isSignOut, String loggedinUser)
        {
            try
            {

                //string emailId = Common.Common.GetEmailFromClaims(this.Page.User as IPrincipal);
                //List<string> entitlements = Common.Common.GetClaims(emailId);
                //if (entitlements.Count > 0)
                //{
                //    OCHandlerService.HandlerServiceClient objHandlerServiceClient = new OCHandlerService.HandlerServiceClient();
                //    string UserType = GetConstant.GetElementValue("Claims", "ClaimName_UserType");
                //    string UserTypeValue = GetConstant.GetElementValue("Claims", "ClaimeValue_UserType_SSO");
                //    entitlements = entitlements.FindAll(e => String.Equals(e.Split('/')[0], UserType, StringComparison.InvariantCultureIgnoreCase)
                //                                         && String.Equals(e.Split('/')[1], UserTypeValue, StringComparison.InvariantCultureIgnoreCase));
                //    if (entitlements.Count > 0)
                //    {
                //        objHandlerServiceClient.InsertSSOAuditLogUser(loggedinUser, emailId, DateTime.Now, DateTime.Now, isSignOut);
                //    }
//
                //}
            }
            catch (Exception ex)
            {
                //To log
            }


        }
        #endregion SSO Audit

        public static string GetEmailFromClaims(IPrincipal claimsPrincipal)
        {
            String emailId = null;
            IClaimsIdentity claimsIdentity = (IClaimsIdentity)claimsPrincipal.Identity;
            ClaimCollection claimcol = claimsIdentity.Claims;

            Dictionary<string, string> constantValues = new Dictionary<string, string>();
            constantValues.Add("IDPROVIDERCLAIMTYPE", "http://schemas.microsoft.com/sharepoint/2009/08/claims/identityprovider");
            constantValues.Add("UPNCLAIMTYPE", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn");
            constantValues.Add("EMAILCLAIMTYPE", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress");

            String IdProvider = GetClaimValue(constantValues["IDPROVIDERCLAIMTYPE"], claimcol);

            if (String.Equals(IdProvider, "windows", StringComparison.InvariantCultureIgnoreCase))
            {
                return GetClaimValue(constantValues["UPNCLAIMTYPE"], claimcol);
            }
            else //Claims
            {
                emailId = GetClaimValue(constantValues["EMAILCLAIMTYPE"], claimcol);
                emailId = Convert.ToString(emailId, CultureInfo.InvariantCulture);
                return emailId;
            }

        }

        private static string GetClaimValue(string claim, IList<Claim> claims)
        {
            foreach (Claim c in claims)
            {
                if (String.Equals(c.ClaimType, claim, StringComparison.InvariantCultureIgnoreCase))
                {
                    return c.Value;
                }
            }
            return null;
        }

        private string EncryptQueryValues(string valueToEncrypt, string EncryptionKey)
        {
            try
            {
                string VendorHashKeyValue = EncryptionKey;
                TripleDESCryptoServiceProvider l3DESCryptoServiceProvider = new TripleDESCryptoServiceProvider();
                l3DESCryptoServiceProvider.Mode = CipherMode.CBC;
                l3DESCryptoServiceProvider.Key = TruncateHash(VendorHashKeyValue, 24);
                l3DESCryptoServiceProvider.IV = TruncateHash("", 8);

                // Convert the plaintext string to a byte array.
                byte[] plaintextBytes = System.Text.Encoding.Unicode.GetBytes(valueToEncrypt);

                // Create the stream.
                System.IO.MemoryStream ms = new System.IO.MemoryStream();
                // Create the encoder to write to the stream.
                CryptoStream encStream = new CryptoStream(ms, l3DESCryptoServiceProvider.CreateEncryptor(), CryptoStreamMode.Write);

                // Use the crypto stream to write the byte array to the stream.
                encStream.Write(plaintextBytes, 0, plaintextBytes.Length);
                encStream.FlushFinalBlock();

                // Convert the encrypted stream to a printable string.
                string output = Convert.ToBase64String(ms.ToArray());
                ms.Close();

                return output;
            }
            catch (Exception ex)
            {
                return null;
            }
        }


        private byte[] TruncateHash(string key, int length)
        {
            try
            {
                SHA1CryptoServiceProvider sha1 = new SHA1CryptoServiceProvider();

                // Hash the key.
                byte[] keyBytes = System.Text.Encoding.Unicode.GetBytes(key);
                byte[] hash = sha1.ComputeHash(keyBytes);

                // Truncate or pad the hash.
                Array.Resize(ref hash, length);
                return hash;
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
