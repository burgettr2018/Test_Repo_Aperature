using System;
using System.Linq;
using System.ServiceModel;
using System.Runtime.Serialization;

namespace OCUserService.Services
{
    [DataContract]
    public enum ErrorCode
    {
        [EnumMember(Value = "User {0} created successfully")]        
        UserCreatedSuccessfully,
        [EnumMember(Value = "User {0} disabled successfully")]        
        UserDisabledSuccessfully,
        [EnumMember(Value = "User {0} reenabled successfully")]        
        UserReenabledSuccessfully,
    }
    [DataContract]
    public enum ErrorStatus
    {
        [EnumMember(Value = "Success")]
        Success,
        [EnumMember(Value = "Failure")]
        Failure,
    }

    [DataContract]
    public class MessageDetailsDataObject
    {
        public MessageDetailsDataObject(ErrorCode code, ErrorStatus status, string messageParam)
            : this(code, status)
        {
            ErrorMessage = string.Format(ErrorMessage, messageParam);
        }
        public MessageDetailsDataObject(ErrorCode code, ErrorStatus status)
        {
            ErrorCode = code;
            ErrorStatus = status;
            ErrorMessage = GetDescriptionFromEnumValue(code);
        }

        [DataMember]
        public string ErrorMessage { get; private set; }

        [DataMember(Name = "ErrorCode")]
        private string ErrorCodeSerialization
        {
            get
            {
                return Enum.GetName(typeof(ErrorCode), ErrorCode);
            }
            set
            {
                ErrorCode = (ErrorCode)Enum.Parse(typeof(ErrorCode), value);
            }
        }
        public ErrorCode ErrorCode { get; private set; }

        [DataMember(Name = "ErrorStatus")]
        private string ErrorStatusSerialization
        {
            get
            {
                return Enum.GetName(typeof(ErrorStatus), ErrorStatus);
            }
            set
            {
                ErrorStatus = (ErrorStatus)Enum.Parse(typeof(ErrorStatus), value);
            }
        }
        public ErrorStatus ErrorStatus { get; private set; }

        private static string GetDescriptionFromEnumValue(Enum value)
        {
            EnumMemberAttribute attribute = value.GetType()
                .GetField(value.ToString())
                .GetCustomAttributes(typeof(EnumMemberAttribute), false)
                .SingleOrDefault() as EnumMemberAttribute;
            return attribute == null ? value.ToString() : attribute.Value;
        }
    }
}