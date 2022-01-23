SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRateCardHistory]
(
 @val [dbo].[RateCardHistory] READONLY
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
MERGE [dbo].[RateCardHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CurrencyId]=S.[CurrencyId],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[Name]=S.[Name],[RateCardFile_Content]=S.[RateCardFile_Content],[RateCardFile_Source]=S.[RateCardFile_Source],[RateCardFile_Type]=S.[RateCardFile_Type],[RateCardId]=S.[RateCardId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CurrencyId],[Description],[IsActive],[IsDefault],[Name],[RateCardFile_Content],[RateCardFile_Source],[RateCardFile_Type],[RateCardId],[VendorId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[Description],S.[IsActive],S.[IsDefault],S.[Name],S.[RateCardFile_Content],S.[RateCardFile_Source],S.[RateCardFile_Type],S.[RateCardId],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
