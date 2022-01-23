SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateSameDayCreditApprovalsAndReplacementAmount]  
(  
@CreditProfileId BIGINT,  
@CustomerId BIGINT,  
@change Decimal(18,2),  
@exchangerate Decimal(20,8),  
@canReplaceReplacementSchedule BIT,  
@canUpdateSameDayCreditApproval BIT,  
@CreatedById BIGINT,  
@CreatedTime DATETIMEOFFSET  
)  
AS  
Declare @PreviousApproved_Amount decimal(18,2)=0.00  
Declare @CurrentApproved_Amount decimal(18,2)=0.00  
DECLARE @UpdateQuery NVARCHAR(MAX)  
SET @UpdateQuery = ''  
BEGIN  
SET NOCOUNT ON  
Create Table #PartyIds(Id int ,Change DECIMAL(20,2))  
Create Table #Replacements(ContractId int, ReplacementAmount DECIMAL(16,2))  
IF(@canUpdateSameDayCreditApproval=1)  
BEGIN  
SELECT TOP 1 @PreviousApproved_Amount = ApprovedAmount_Amount from CreditDecisions WHERE CreditProfileId=@CreditProfileId and IsActive=0  ORDER BY Id DESC  
SELECT TOP 1 @CurrentApproved_Amount = ApprovedAmount_Amount from CreditDecisions WHERE CreditProfileId=@CreditProfileId and IsActive=1  ORDER BY Id DESC  
Insert Into #PartyIds values(@CustomerId, 100 * @change)  
Insert Into #PartyIds  
Select Parent.Id , 100.00 * @change from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Parent ON Parties.ParentPartyId = Parent.Id  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'  
Insert Into #PartyIds  
Select Child.Id , 100 * @change from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Child ON Parties.Id = Child.ParentPartyId  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'  
Insert Into #PartyIds  
Select Sibling.Id , 100 * @change  from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Sibling ON Parties.ParentPartyId = Sibling.ParentPartyId  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'AND Sibling.ParentPartyId IS NOT NULL  
Insert Into #PartyIds  
Select DISTINCT CustomerTP.ThirdPartyId , 100 * @change from CreditProfileThirdPartyRelationships CreditTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON CreditTP.ThirdPartyRelationshipId = CustomerTP.Id  
WHERE CreditTP.CreditProfileId = @CreditProfileId AND  
(CustomerTP.RelationshipType = 'CoBorrower' OR CustomerTP.RelationshipType = 'CoLessee') AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds) AND  
CreditTP.IsActive = 1  
Insert Into #PartyIds  
Select CustomerTP.ThirdPartyId ,  
CASE WHEN CreditTP.IsActive=1  
THEN  
Case WHEN ThirdPartyCustomer.SameDayCreditApprovals_Amount=0.00  
THEN  
CASE WHEN @change=0.0  
THEN CreditTP.RelationshipPercentage * (@change + @CurrentApproved_Amount)  
ELSE CreditTP.RelationshipPercentage * (@change + @PreviousApproved_Amount)  
END  
ELSE  CreditTP.RelationshipPercentage * @change END  
ELSE  
CASE WHEN @change=0.0  
THEN ThirdPartyCustomer.SameDayCreditApprovals_Amount-@CurrentApproved_Amount  
ELSE ThirdPartyCustomer.SameDayCreditApprovals_Amount-@PreviousApproved_Amount  
END  
END  
from CreditProfileThirdPartyRelationships CreditTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON CreditTP.ThirdPartyRelationshipId = CustomerTP.Id  
JOIN Customers CreditProfileCustomer ON CustomerTP.CustomerId=CreditProfileCustomer.Id  
JOIN Customers ThirdPartyCustomer ON CustomerTP.ThirdPartyId=ThirdPartyCustomer.Id  
WHERE CreditTP.CreditProfileId = @CreditProfileId AND  
CustomerTP.RelationshipType = 'CorporateGuarantor' AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds)  
Insert Into #PartyIds  
Select CustomerTP.ThirdPartyId ,  
CASE WHEN CreditTP.IsActive=1  
THEN  
Case WHEN ThirdPartyCustomer.SameDayCreditApprovals_Amount=0.00  
THEN  
CASE WHEN @change=0.0  
THEN CreditTP.RelationshipPercentage * (@change + @CurrentApproved_Amount)  
ELSE CreditTP.RelationshipPercentage * (@change + @PreviousApproved_Amount)  
END  
ELSE  CreditTP.RelationshipPercentage * @change END  
ELSE  
CASE WHEN @change=0.0  
THEN ThirdPartyCustomer.SameDayCreditApprovals_Amount-@CurrentApproved_Amount  
ELSE ThirdPartyCustomer.SameDayCreditApprovals_Amount-@PreviousApproved_Amount  
END  
END  
from CreditProfileThirdPartyRelationships CreditTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON CreditTP.ThirdPartyRelationshipId = CustomerTP.Id  
JOIN Customers CreditProfileCustomer ON CustomerTP.CustomerId=CreditProfileCustomer.Id  
JOIN Customers ThirdPartyCustomer ON CustomerTP.ThirdPartyId=ThirdPartyCustomer.Id  
WHERE CreditTP.CreditProfileId = @CreditProfileId AND  
CustomerTP.RelationshipType = 'PersonalGuarantor' AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds)  
SET @UpdateQuery = 'UPDATE Customers  
SET SameDayCreditApprovals_Amount = SameDayCreditApprovals_Amount + (#PartyIds.Change / 100.00) , UpdatedById = ' + CAST(@CreatedById AS NVARCHAR(MAX)) + ', UpdatedTime = ''' + CAST(@CreatedTime AS NVARCHAR(MAX)) + '''  
FROM Customers JOIN #PartyIds ON Customers.Id = #PartyIds.Id'  
EXEC(@UpdateQuery)  
END  
IF(@canReplaceReplacementSchedule = 1)  
BEGIN  
TRUNCATE TABLE #PartyIds  
Insert Into #Replacements  
Select ContractId ,ReplacementAmount_Amount FROM CreditProfileContractReplacements  
Where CreditProfileContractReplacements.CreditProfileId = @CreditProfileId AND CreditProfileContractReplacements.IsActive = 1  
DECLARE @SUM_OF_ReplacementAmount DECIMAL(18,2)  
SELECT @SUM_OF_ReplacementAmount = SUM(ReplacementAmount) from #Replacements  
Insert Into #PartyIds values(@CustomerId, 100 * @SUM_OF_ReplacementAmount * @exchangerate)  
Insert Into #PartyIds  
Select Parent.Id , 100 * @SUM_OF_ReplacementAmount * @exchangerate  from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Parent ON Parties.ParentPartyId = Parent.Id  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'  
Insert Into #PartyIds  
Select Child.Id , 100 *  @SUM_OF_ReplacementAmount * @exchangerate from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Child ON Parties.Id = Child.ParentPartyId  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'  
Insert Into #PartyIds  
Select Sibling.Id , 100 * @SUM_OF_ReplacementAmount * @exchangerate from Parties  
JOIN Customers ON Parties.Id = Customers.Id  
JOIN Parties Sibling ON Parties.ParentPartyId = Sibling.ParentPartyId  
WHERE Customers.Id = @CustomerId AND Customers.Status != 'Inactive'AND Sibling.ParentPartyId IS NOT NULL  
;WITH CTE_DISTINCT_CO_RECORD  
AS  
(  
SELECT ContractTP.ContractId ContractId,CustomerTP.ThirdPartyId ThirdPartyId ,ContractTP.Id ContractTPId, ROW_NUMBER() OVER (PARTITION BY ContractTP.ContractId, CustomerTP.ThirdPartyId ORDER BY ContractTP.ID) RowNum  
FROM ContractThirdPartyRelationships ContractTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id  
WHERE (CustomerTP.RelationshipType = 'CoBorrower' OR CustomerTP.RelationshipType = 'CoLessee') AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds) AND  
ContractTP.IsActive = 1  
)  
Insert Into #PartyIds  
Select CTE_DISTINCT_CO_RECORD.ThirdPartyId , SUM(100.00 * #Replacements.ReplacementAmount * @exchangerate)  
FROM CTE_DISTINCT_CO_RECORD  
JOIN ContractThirdPartyRelationships ContractTP ON CTE_DISTINCT_CO_RECORD.ContractTPId = ContractTP.Id  
JOIN #Replacements ON CTE_DISTINCT_CO_RECORD.ContractId = #Replacements.ContractId  
WHERE CTE_DISTINCT_CO_RECORD.RowNum = 1  
Group BY CTE_DISTINCT_CO_RECORD.ThirdPartyId  
Insert Into #PartyIds  
Select CustomerTP.ThirdPartyId , SUM(ContractTP.RelationshipPercentage * #Replacements.ReplacementAmount * @exchangerate) from ContractThirdPartyRelationships ContractTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id  
JOIN #Replacements ON ContractTP.ContractId = #Replacements.ContractId  
WHERE CustomerTP.RelationshipType = 'CorporateGuarantor' AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds) AND  
ContractTP.IsActive = 1  
Group BY CustomerTP.ThirdPartyId  
Insert Into #PartyIds  
Select CustomerTP.ThirdPartyId , SUM(ContractTP.RelationshipPercentage * #Replacements.ReplacementAmount * @exchangerate) from ContractThirdPartyRelationships ContractTP  
JOIN CustomerThirdPartyRelationships CustomerTP ON ContractTP.ThirdPartyRelationshipId = CustomerTP.Id  
JOIN #Replacements ON ContractTP.ContractId = #Replacements.ContractId  
WHERE CustomerTP.RelationshipType = 'PersonalGuarantor' AND  
CustomerTP.ThirdPartyId NOT IN (SELECT ID FROM #PartyIds) AND  
ContractTP.IsActive = 1  
Group BY CustomerTP.ThirdPartyId  
SET @UpdateQuery = 'UPDATE Customers  
SET ReplacementAmount_Amount = ReplacementAmount_Amount + ( #PartyIds.Change / 100.00) , UpdatedById = ' + CAST(@CreatedById AS NVARCHAR(MAX)) + ', UpdatedTime = ''' + CAST(@CreatedTime AS NVARCHAR(MAX)) + '''  
FROM Customers JOIN #PartyIds ON Customers.Id = #PartyIds.Id'  
EXEC(@UpdateQuery)  
END  
DROP TABLE #PartyIds  
DROP TABLE #Replacements  
END

GO
