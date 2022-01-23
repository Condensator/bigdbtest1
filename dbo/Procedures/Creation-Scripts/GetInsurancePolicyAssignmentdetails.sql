SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Proc [dbo].[GetInsurancePolicyAssignmentdetails](
@LegalEntityID nvarchar(max),
@ContractID BigInt,
@CustomerID bigint
)
As
Begin
Declare @Sqlstring nvarchar(max)
Set @Sqlstring=
'With Cte_GetAnticipatedFundingDate(CommencementDate,Id)
As
(
Select
Min(payableInvoice.DueDate)
,loanFinance.Id
From LoanFinances loanFinance
Left Join LoanFundings loanFunding  On loanFinance.Id = loanFunding.LoanFinanceId
Left Join PayableInvoices payableInvoice On loanFunding.FundingId= payableInvoice.Id
Group By loanFinance.Id)
Select
PartyNumber
,SequenceNumber
,ContractType
,PartyName
,InsuranceCompanyName
,EffectiveDate
,ExpirationDate
,PolicyNumber
,PartyId
,ContractId
,ContractAlias
,Daysindeal
From (
Select
Parties.PartyNumber
,Contracts.SequenceNumber
,contracts.ContractType
,Parties.PartyName
,InsuranceCompanies.Name As ''InsuranceCompanyName''
,InsurancePolicies.EffectiveDate
,InsurancePolicies.ExpirationDate
,InsurancePolicies.PolicyNumber
,Parties.Id As PartyId
,Contracts.Id As ContractId
,Contracts.Alias As ''ContractAlias''
,ABS(DateDiff(Day,LeaseFinanceDetails.CommencementDate,GETDATE())) As Daysindeal
From InsurancePolicies
Join InsurancePolicyAssignments on InsurancePolicies.id=InsurancePolicyAssignments.InsurancePolicyId
Join contracts on InsurancePolicyAssignments.ContractId=Contracts.Id
Join LeaseFinances on contracts.id=LeaseFinances.ContractId and LeaseFinances.IsCurrent = 1
Join parties on InsurancePolicies.CustomerId=Parties.id
Left Join LeaseFinanceDetails on LeaseFinances.Id=LeaseFinanceDetails.Id
Left Join InsuranceCompanies on InsurancePolicies.InsuranceCompanyId=InsuranceCompanies.Id
Where InsurancePolicies.Isactive=1
And InsurancePolicyAssignments.Isactive=1
LeaselegalCondition
CustomerCondition
ContractCondition
Union All
Select
Parties.PartyNumber
,Contracts.SequenceNumber
,contracts.ContractType
,Parties.PartyName
,InsuranceCompanies.Name  As ''InsuranceCompanyName''
,InsurancePolicies.EffectiveDate
,InsurancePolicies.ExpirationDate
,InsurancePolicies.PolicyNumber
,Parties.Id as PartyId
,Contracts.Id As ContractId
,Contracts.Alias As ''ContractAlias''
,Case When ContractType=''Loan''
Then
ABS(DATEDIFF(day,LoanFinances.CommencementDate,GETDATE()) )
Else
ABS(DATEDIFF(day,Cte_GetAnticipatedFundingDate.CommencementDate,GETDATE()))
End As Daysindeal
From InsurancePolicies
Join InsurancePolicyAssignments on InsurancePolicies.id=InsurancePolicyAssignments.InsurancePolicyId
Join contracts on InsurancePolicyAssignments.ContractId=Contracts.Id
Join LoanFinances on contracts.id=LoanFinances.ContractId and LoanFinances.IsCurrent = 1
Join parties on InsurancePolicies.CustomerId=Parties.id
Left Join InsuranceCompanies on InsurancePolicies.InsuranceCompanyId=InsuranceCompanies.Id
Left Join Cte_GetAnticipatedFundingDate on LoanFinances.Id =Cte_GetAnticipatedFundingDate.id
Where InsurancePolicies.Isactive=1
And InsurancePolicyAssignments.isactive=1
loanlegalCondition
CustomerCondition
ContractCondition
InsurancePoliciesWithoutContracts
) as temp order by PartyId
,ContractId'
If(@ContractID!=null or @ContractID!='' )
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'ContractCondition' ,'And contracts.ID = @ContractID')
Set @Sqlstring=REPLACE(@Sqlstring,'InsurancePoliciesWithoutContracts' ,'')
End
Else
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'ContractCondition' ,'')
Set @Sqlstring=REPLACE(@Sqlstring,'InsurancePoliciesWithoutContracts' ,'
Union all
Select
Parties.PartyNumber
,'''' SequenceNumber
,'''' ContractType
,Parties.PartyName
,InsuranceCompanies.Name As ''InsuranceCompanyName''
,InsurancePolicies.EffectiveDate
,InsurancePolicies.ExpirationDate
,InsurancePolicies.PolicyNumber
,Parties.Id As PartyId
,null As ContractId
,null As ''ContractAlias''
,null As Daysindeal
From InsurancePolicies
Left Join parties on InsurancePolicies.CustomerId=Parties.id
Left Join InsuranceCompanies on InsurancePolicies.InsuranceCompanyId=InsuranceCompanies.Id
Where InsurancePolicies.id Not In (Select InsurancePolicyAssignments.InsurancePolicyId From InsurancePolicyAssignments)
And InsurancePolicies.Isactive=1
CustomerCondition
legalcondition')
End
If(@CustomerID!=null or @CustomerID!='' )
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'CustomerCondition' ,'And InsurancePolicies.CustomerID = @CustomerId')
End
Else
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'CustomerCondition' ,'')
End
If(@LegalEntityID!=null or @LegalEntityID!='' )
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'loanlegalCondition' ,'And LoanFinances.LegalEntityId in (select value from String_split(@LegalEntityID,'',''))')
Set @Sqlstring=REPLACE(@Sqlstring,'leaselegalCondition' ,'And  LeaseFinances.LegalEntityId in (select value from String_split(@LegalEntityID,'',''))')
Set @Sqlstring=REPLACE(@Sqlstring,'legalcondition' ,'And  InsurancePolicies.LegalEntityId in (select value from String_split(@LegalEntityID,'',''))')
End
Else
Begin
Set @Sqlstring=REPLACE(@Sqlstring,'loanlegalCondition' ,'')
Set @Sqlstring=REPLACE(@Sqlstring,'leaselegalCondition' ,'')
Set @Sqlstring=REPLACE(@Sqlstring,'legalcondition' ,'')
End
EXECUTE sp_executesql @Sqlstring,
N'
@LegalEntityID nvarchar(max)
,@CustomerID bigint
,@ContractID bigint',
@LegalEntityID
,@CustomerID
,@ContractID
End

GO
