SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[GetInsurancePolicyExpirationDetails]
(@CustomerID bigint,
@FromDate datetime,
@ToDate datetime,
@Culture NVARCHAR(10)
)
As
Begin
Declare @Sqlstring nvarchar(max)
set @Sqlstring='
Select
Currencies.Name As Currency
,PartyNumber
,Parties.PartyName
,Type
,InsuranceCompanies.Name As InsuranceCompanyName
,InsurancePolicies.PolicyNumber
,Convert(Date,InsurancePolicies.ExpirationDate) As ExpirationDate
,ISNULL(EntityResourceForCoverageType.Value,CoverageTypeConfigs.CoverageType) AS CoverageType
,InsurancePolicyCoverageDetails.PerOccurrenceAmount_Amount
,InsuranceAgencies.Name As InsuranceAgent
,InsuranceAgencies.PhoneNumber As InsuranceAgentContactNumber
,PartyContacts.FullName As CustomerInsuranceContact
From InsurancePolicies
Left Join InsuranceCompanies on InsurancePolicies.InsuranceCompanyId=InsuranceCompanies.Id
Left Join Currencies on InsurancePolicies.CurrencyId =Currencies.Id
Left Join InsurancePolicyCoverageDetails on InsurancePolicies.Id=InsurancePolicyCoverageDetails.InsurancePolicyId
Left Join CoverageTypeConfigs on InsurancePolicyCoverageDetails.CoverageTypeConfigId=CoverageTypeConfigs.Id
Left Join InsuranceAgencies on InsurancePolicies.InsuranceAgencyId=InsuranceAgencies.Id
Left Join Parties on InsurancePolicies.CustomerId = Parties.Id
Left Join PartyContacts on Parties.id = PartyContacts.PartyId and InsurancePolicies.ContactPersonId = PartyContacts.Id
Left Join EntityResources EntityResourceForCoverageType ON CoverageTypeConfigs.Id = EntityResourceForCoverageType.EntityId
And EntityResourceForCoverageType.EntityType =''CoverageTypeConfig''
And EntityResourceForCoverageType.Name =''CoverageType''
And EntityResourceForCoverageType.Culture = @Culture
Where InsurancePolicyCoverageDetails.Isactive=1
DateCondition
CustomerCondition
Group By
Currencies.Name
,PartyNumber
,Parties.PartyName
,Type
,InsurancePolicies.PolicyNumber
,InsuranceCompanies.Name
,InsuranceAgencies.Name
,InsuranceAgencies.PhoneNumber
,InsurancePolicies.ExpirationDate
,ISNULL(EntityResourceForCoverageType.Value,CoverageTypeConfigs.CoverageType)
,InsurancePolicyCoverageDetails.PerOccurrenceAmount_Amount
,PartyContacts.FullName
'
If((@FromDate!=null or @FromDate!='')  and (@ToDate!=null or @ToDate!=''))
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'DateCondition' ,'And InsurancePolicies.ExpirationDate Between @FromDate And @ToDate')
End
Else If (@FromDate!=null or @FromDate!='')
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'DateCondition' ,'And InsurancePolicies.ExpirationDate >= @FromDate')
End
Else If (@ToDate!=null or  @ToDate!='')
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'DateCondition' ,'And InsurancePolicies.ExpirationDate <= @ToDate')
End
Else
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'DateCondition' ,'')
End
If(@CustomerID!=null or @CustomerID!='' )
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'CustomerCondition' ,'And CustomerID = @CustomerId')
End
Else
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'CustomerCondition' ,'')
End
EXECUTE sp_executesql @Sqlstring,
N'@FromDate datetime
,@ToDate datetime
,@CustomerID bigint
,@Culture NVARCHAR(10)',
@FromDate
,@ToDate
,@CustomerID
,@Culture
End

GO
