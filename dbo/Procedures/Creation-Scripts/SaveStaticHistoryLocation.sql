SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveStaticHistoryLocation]
(
 @val [dbo].[StaticHistoryLocation] READONLY
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
MERGE [dbo].[StaticHistoryLocations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Address]=S.[Address],[City]=S.[City],[Country]=S.[Country],[County]=S.[County],[LocationCode]=S.[LocationCode],[PostalCode]=S.[PostalCode],[State]=S.[State],[TaxBasisType]=S.[TaxBasisType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Address],[City],[Country],[County],[CreatedById],[CreatedTime],[LocationCode],[PostalCode],[State],[TaxBasisType])
    VALUES (S.[Address],S.[City],S.[Country],S.[County],S.[CreatedById],S.[CreatedTime],S.[LocationCode],S.[PostalCode],S.[State],S.[TaxBasisType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
