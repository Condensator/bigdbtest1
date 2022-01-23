SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerThirdPartyRelationship]
(
 @val [dbo].[CustomerThirdPartyRelationship] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[CustomerThirdPartyRelationships] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[Coverage]=S.[Coverage],[DeactivationDate]=S.[DeactivationDate],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsAssumptionApproved]=S.[IsAssumptionApproved],[IsFromAssumption]=S.[IsFromAssumption],[IsNewAddress]=S.[IsNewAddress],[IsNewContact]=S.[IsNewContact],[IsNewRelation]=S.[IsNewRelation],[LimitByAmount_Amount]=S.[LimitByAmount_Amount],[LimitByAmount_Currency]=S.[LimitByAmount_Currency],[LimitByDurationInMonths]=S.[LimitByDurationInMonths],[LimitByPercentage]=S.[LimitByPercentage],[PersonalGuarantorCustomerOrContact]=S.[PersonalGuarantorCustomerOrContact],[RelationshipType]=S.[RelationshipType],[Scope]=S.[Scope],[ThirdPartyAddressId]=S.[ThirdPartyAddressId],[ThirdPartyContactId]=S.[ThirdPartyContactId],[ThirdPartyId]=S.[ThirdPartyId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[Coverage],[CreatedById],[CreatedTime],[CustomerId],[DeactivationDate],[Description],[IsActive],[IsAssumptionApproved],[IsFromAssumption],[IsNewAddress],[IsNewContact],[IsNewRelation],[LimitByAmount_Amount],[LimitByAmount_Currency],[LimitByDurationInMonths],[LimitByPercentage],[PersonalGuarantorCustomerOrContact],[RelationshipType],[Scope],[ThirdPartyAddressId],[ThirdPartyContactId],[ThirdPartyId],[VendorId])
    VALUES (S.[ActivationDate],S.[Coverage],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DeactivationDate],S.[Description],S.[IsActive],S.[IsAssumptionApproved],S.[IsFromAssumption],S.[IsNewAddress],S.[IsNewContact],S.[IsNewRelation],S.[LimitByAmount_Amount],S.[LimitByAmount_Currency],S.[LimitByDurationInMonths],S.[LimitByPercentage],S.[PersonalGuarantorCustomerOrContact],S.[RelationshipType],S.[Scope],S.[ThirdPartyAddressId],S.[ThirdPartyContactId],S.[ThirdPartyId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
