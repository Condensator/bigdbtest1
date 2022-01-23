SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePaynetDirectLOS]
(
 @val [dbo].[PaynetDirectLOS] READONLY
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
MERGE [dbo].[PaynetDirectLOS] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ConfidenceIndicator]=S.[ConfidenceIndicator],[IsActive]=S.[IsActive],[MainAddress]=S.[MainAddress],[PaynetCustomerName]=S.[PaynetCustomerName],[PaynetCustomerNumber]=S.[PaynetCustomerNumber],[SSN]=S.[SSN],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ConfidenceIndicator],[CreatedById],[CreatedTime],[IsActive],[MainAddress],[PaynetCustomerName],[PaynetCustomerNumber],[PaynetDirectDetailId],[SSN])
    VALUES (S.[ConfidenceIndicator],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[MainAddress],S.[PaynetCustomerName],S.[PaynetCustomerNumber],S.[PaynetDirectDetailId],S.[SSN])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
