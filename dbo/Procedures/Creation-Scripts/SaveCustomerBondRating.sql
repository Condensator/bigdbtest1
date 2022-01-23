SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerBondRating]
(
 @val [dbo].[CustomerBondRating] READONLY
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
MERGE [dbo].[CustomerBondRatings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Agency]=S.[Agency],[AgencyCustomerName]=S.[AgencyCustomerName],[AgencyCustomerNumber]=S.[AgencyCustomerNumber],[AsOfDate]=S.[AsOfDate],[BondRatingId]=S.[BondRatingId],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Agency],[AgencyCustomerName],[AgencyCustomerNumber],[AsOfDate],[BondRatingId],[CreatedById],[CreatedTime],[CustomerId],[IsActive])
    VALUES (S.[Agency],S.[AgencyCustomerName],S.[AgencyCustomerNumber],S.[AsOfDate],S.[BondRatingId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IsActive])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
