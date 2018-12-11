using System;
using System.Linq;
using System.ServiceModel;
using System.Runtime.Serialization;

namespace OCUserService.Services
{
    [DataContract]
    public class UserDetailsDataObject
    {
        public UserDetailsDataObject(string userName, string firstName, string lastName, string emailAddress, int userAccountControl)
        {
            UserName = userName;
            FirstName = firstName;
            LastName = lastName;
            EmailAddress = emailAddress;
            UserAccountControl = userAccountControl;
        }

        [DataMember]
        public string UserName { get; set; }
        [DataMember]
        public string FirstName { get; set; }
        [DataMember]
        public string LastName { get; set; }
        [DataMember]
        public string EmailAddress { get; set; }
        [DataMember]
        public int UserAccountControl { get; set; }

    }
}