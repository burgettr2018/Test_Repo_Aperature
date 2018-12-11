using System;
using System.ServiceModel;

namespace OCUserService.Services
{
    [ServiceContract]
    public interface IUserService
    {
        [OperationContract]
        MessageDetailsDataObject AddOrEnableUser(string userName, string firstName, string lastName, string emailAddress, string password);
        [OperationContract]
        MessageDetailsDataObject DisableUser(string userName);
        [OperationContract]
        UserDetailsDataObject GetUserDetailsByUserName(string userName);
        [OperationContract]
        UserDetailsDataObject GetUserDetailsByEmailAddress(string emailAddress);
    }
}