SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorLegalEntity]
(
 @val [dbo].[VendorLegalEntity] READONLY
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
MERGE [dbo].[VendorLegalEntities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CumulativeFundingLimit_Amount]=S.[CumulativeFundingLimit_Amount],[CumulativeFundingLimit_Currency]=S.[CumulativeFundingLimit_Currency],[IsActive]=S.[IsActive],[IsApproved]=S.[IsApproved],[IsOnHold]=S.[IsOnHold],[LegalEntityId]=S.[LegalEntityId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CumulativeFundingLimit_Amount],[CumulativeFundingLimit_Currency],[IsActive],[IsApproved],[IsOnHold],[LegalEntityId],[VendorId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CumulativeFundingLimit_Amount],S.[CumulativeFundingLimit_Currency],S.[IsActive],S.[IsApproved],S.[IsOnHold],S.[LegalEntityId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
