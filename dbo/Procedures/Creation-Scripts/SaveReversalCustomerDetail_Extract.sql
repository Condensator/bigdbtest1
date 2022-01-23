SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReversalCustomerDetail_Extract]
(
 @val [dbo].[ReversalCustomerDetail_Extract] READONLY
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
MERGE [dbo].[ReversalCustomerDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ClassCode]=S.[ClassCode],[CustomerId]=S.[CustomerId],[CustomerNumber]=S.[CustomerNumber],[ISOCountryCode]=S.[ISOCountryCode],[JobStepInstanceId]=S.[JobStepInstanceId],[PartyName]=S.[PartyName],[TaxRegistrationNumber]=S.[TaxRegistrationNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ClassCode],[CreatedById],[CreatedTime],[CustomerId],[CustomerNumber],[ISOCountryCode],[JobStepInstanceId],[PartyName],[TaxRegistrationNumber])
    VALUES (S.[ClassCode],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[CustomerNumber],S.[ISOCountryCode],S.[JobStepInstanceId],S.[PartyName],S.[TaxRegistrationNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
