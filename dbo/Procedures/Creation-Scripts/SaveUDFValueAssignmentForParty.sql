SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUDFValueAssignmentForParty]
(
 @val [dbo].[UDFValueAssignmentForParty] READONLY
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
MERGE [dbo].[UDFValueAssignmentForParties] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[IsActive]=S.[IsActive],[PortfolioId]=S.[PortfolioId],[UDF1Value]=S.[UDF1Value],[UDF2Value]=S.[UDF2Value],[UDF3Value]=S.[UDF3Value],[UDF4Value]=S.[UDF4Value],[UDF5Value]=S.[UDF5Value],[UDFLabelForPartyDetailId]=S.[UDFLabelForPartyDetailId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EntityId],[EntityType],[IsActive],[PortfolioId],[UDF1Value],[UDF2Value],[UDF3Value],[UDF4Value],[UDF5Value],[UDFLabelForPartyDetailId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityType],S.[IsActive],S.[PortfolioId],S.[UDF1Value],S.[UDF2Value],S.[UDF3Value],S.[UDF4Value],S.[UDF5Value],S.[UDFLabelForPartyDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
