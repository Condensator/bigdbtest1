SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReferralBanker]
(
 @val [dbo].[ReferralBanker] READONLY
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
MERGE [dbo].[ReferralBankers] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CostCenterName]=S.[CostCenterName],[ExternalApplicationId]=S.[ExternalApplicationId],[FirstName]=S.[FirstName],[IsActive]=S.[IsActive],[LastName]=S.[LastName],[OfficeNumber]=S.[OfficeNumber],[RegionName]=S.[RegionName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CostCenterName],[CreatedById],[CreatedTime],[ExternalApplicationId],[FirstName],[IsActive],[LastName],[OfficeNumber],[RegionName])
    VALUES (S.[CostCenterName],S.[CreatedById],S.[CreatedTime],S.[ExternalApplicationId],S.[FirstName],S.[IsActive],S.[LastName],S.[OfficeNumber],S.[RegionName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
