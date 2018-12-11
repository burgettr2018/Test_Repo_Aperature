using System;
using System.Configuration;
using System.Globalization;
using System.Reflection;
using System.ServiceModel;
using System.Text;
using System.DirectoryServices;

namespace OCUserService.Services
{
    // see https://support.microsoft.com/en-us/help/305144/how-to-use-the-useraccountcontrol-flags-to-manipulate-user-account-pro
    public class UserService : IUserService
    {
        public MessageDetailsDataObject AddOrEnableUser(string userName, string firstName, string lastName, string emailAddress, string password)
        {
            try
            {
                // override existing username from email, if exists
                UserDetailsDataObject existingUser = GetUserDetailsByEmailAddress(emailAddress);
                if (existingUser != null)
                {
                    userName = existingUser.UserName;
                }
                using (DirectoryEntry rootDSE = new DirectoryEntry(ConfigurationManager.AppSettings["AD_Connection_String"]))
                {
                    string AD_Group = ConfigurationManager.AppSettings["AD_Group"];
                    DirectorySearcher searcher = new DirectorySearcher(rootDSE, "(OU=" + AD_Group + "*)");
                    SearchResult searchResult = searcher.FindOne();
                    if (searchResult != null)
                    {
                        StringBuilder sb = new StringBuilder();
                        sb.Append(lastName);
                        sb.Append(", ");
                        sb.Append(firstName);

                        DirectoryEntry storeDirectoryEntry = new DirectoryEntry(searchResult.Path);
                        DirectoryEntry userDirectoryEntry = storeDirectoryEntry.Children.Add("CN=" + userName, "user");
                        if (!DirectoryEntry.Exists(userDirectoryEntry.Path))
                        {
                            userDirectoryEntry.Properties["displayName"].Value = Convert.ToString(sb, CultureInfo.InvariantCulture);
                            userDirectoryEntry.Properties["givenName"].Value = firstName;
                            userDirectoryEntry.Properties["sn"].Value = lastName;
                            userDirectoryEntry.Properties["mail"].Value = emailAddress;
                            userDirectoryEntry.Properties["sAMAccountName"].Value = userName;
                            userDirectoryEntry.Properties["userPrincipalName"].Value = userName;
                            userDirectoryEntry.CommitChanges();

                            userDirectoryEntry.Invoke("SetPassword", new object[] { password });
                            //Password Doesn’t Expire	0x10000
                            //NORMAL_ACCOUNT            0x0200
                            userDirectoryEntry.Properties["userAccountControl"].Value = 0x10000 | 0x200;
                            userDirectoryEntry.CommitChanges();

                            return new MessageDetailsDataObject(ErrorCode.UserCreatedSuccessfully, ErrorStatus.Success, userName);
                        }
                        else
                        {
                            userDirectoryEntry = GetUserDirectoryEntryByUserName(userName);
                            if (userDirectoryEntry != null)
                            {
                                userDirectoryEntry.Properties["displayName"].Value = Convert.ToString(sb, CultureInfo.InvariantCulture);
                                userDirectoryEntry.Properties["givenName"].Value = firstName;
                                userDirectoryEntry.Properties["sn"].Value = lastName;
                                userDirectoryEntry.CommitChanges();

                                userDirectoryEntry.Invoke("SetPassword", new object[] { password });
                                //Password Doesn’t Expire	0x10000
                                //NORMAL_ACCOUNT            0x0200
                                userDirectoryEntry.Properties["userAccountControl"].Value = 0x10000 | 0x200;
                                userDirectoryEntry.CommitChanges();

                                return new MessageDetailsDataObject(ErrorCode.UserReenabledSuccessfully, ErrorStatus.Success, userName);
                            }
                            else
                            {
                                throw new Exception(string.Format("Could not find AD user {0} in group {1} despite FindOne saying it existed", userName, AD_Group));
                            }
                        }
                    }
                    throw new Exception(string.Format("Could not find AD group {0}", AD_Group));
                }
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }

        public MessageDetailsDataObject DisableUser(string userName)
        {
            try
            {
                DirectoryEntry entryToUpdate = GetUserDirectoryEntryByUserName(userName);
                if (entryToUpdate != null)
                {
                    int val = (int)entryToUpdate.Properties["userAccountControl"].Value;
                    entryToUpdate.Properties["userAccountControl"].Value = val | 0x2;
                    entryToUpdate.CommitChanges();
                }
                return new MessageDetailsDataObject(ErrorCode.UserDisabledSuccessfully, ErrorStatus.Success, userName);
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }

        public UserDetailsDataObject GetUserDetailsByUserName(string userName)
        {
            try
            {
                DirectoryEntry userDirectoryEntry = GetUserDirectoryEntryByUserName(userName);
                if (userDirectoryEntry != null)
                {
                    return new UserDetailsDataObject(
                        userDirectoryEntry.Properties["sAMAccountName"].Value as string,
                        userDirectoryEntry.Properties["givenName"].Value as string,
                        userDirectoryEntry.Properties["sn"].Value as string,
                        userDirectoryEntry.Properties["mail"].Value as string,
                        (int)userDirectoryEntry.Properties["userAccountControl"].Value
                    );
                }
                return null;
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }

        public UserDetailsDataObject GetUserDetailsByEmailAddress(string emailAddress)
        {
            try
            {
                DirectoryEntry userDirectoryEntry = GetUserDirectoryEntryByEmailAddress(emailAddress);
                if (userDirectoryEntry != null)
                {
                    return new UserDetailsDataObject(
                        userDirectoryEntry.Properties["sAMAccountName"].Value as string,
                        userDirectoryEntry.Properties["givenName"].Value as string,
                        userDirectoryEntry.Properties["sn"].Value as string,
                        userDirectoryEntry.Properties["mail"].Value as string,
                        (int)userDirectoryEntry.Properties["userAccountControl"].Value
                    );
                }
                return null;
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }

        private DirectoryEntry GetUserDirectoryEntryByUserName(string username)
        {
            try
            {
                using (DirectoryEntry rootDSE = new DirectoryEntry(ConfigurationManager.AppSettings["AD_Connection_String"]))
                {
                    DirectorySearcher search = new DirectorySearcher(rootDSE);
                    search.Filter = string.Format(CultureInfo.InvariantCulture, "(sAMAccountName={0})", username.Trim());

                    SearchResult result = search.FindOne();
                    if (result != null)
                    {
                        DirectoryEntry entryToUpdate = result.GetDirectoryEntry();
                        return entryToUpdate;
                    }
                }
                return null;
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }

        private DirectoryEntry GetUserDirectoryEntryByEmailAddress(string emailAddress)
        {
            try
            {
                using (DirectoryEntry rootDSE = new DirectoryEntry(ConfigurationManager.AppSettings["AD_Connection_String"]))
                {
                    DirectorySearcher search = new DirectorySearcher(rootDSE);
                    search.Filter = string.Format(CultureInfo.InvariantCulture, "(mail={0})", emailAddress.Trim());

                    SearchResult result = search.FindOne();
                    if (result != null)
                    {
                        DirectoryEntry entryToUpdate = result.GetDirectoryEntry();
                        return entryToUpdate;
                    }
                }
                return null;
            }
            catch (Exception ex)
            {
                //AppFabricErrorLog.LogErrorDetails(MethodBase.GetCurrentMethod().Name, DetailedError.GenerateDetailedError(ex.Message, ex.StackTrace, ex.InnerException, String.Empty));
                throw new FaultException(String.Format(CultureInfo.InvariantCulture, "Exception in {0}: {1}: {2}", MethodBase.GetCurrentMethod().Name, ex.Message, ex.StackTrace));
            }
        }
    }
}
