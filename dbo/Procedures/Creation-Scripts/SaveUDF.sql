SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUDF]
(
 @val [dbo].[UDF] READONLY
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
MERGE [dbo].[UDFs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ContractId]=S.[ContractId],[CreditApplicationNumber]=S.[CreditApplicationNumber],[CustomerId]=S.[CustomerId],[InvoiceId]=S.[InvoiceId],[IsActive]=S.[IsActive],[QuoteRequestID]=S.[QuoteRequestID],[UDF1Label]=S.[UDF1Label],[UDF1Value]=S.[UDF1Value],[UDF2Label]=S.[UDF2Label],[UDF2Value]=S.[UDF2Value],[UDF3Label]=S.[UDF3Label],[UDF3Value]=S.[UDF3Value],[UDF4Label]=S.[UDF4Label],[UDF4Value]=S.[UDF4Value],[UDF5Label]=S.[UDF5Label],[UDF5Value]=S.[UDF5Value],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[ContractId],[CreatedById],[CreatedTime],[CreditApplicationNumber],[CustomerId],[InvoiceId],[IsActive],[QuoteRequestID],[UDF1Label],[UDF1Value],[UDF2Label],[UDF2Value],[UDF3Label],[UDF3Value],[UDF4Label],[UDF4Value],[UDF5Label],[UDF5Value],[VendorId])
    VALUES (S.[AssetId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationNumber],S.[CustomerId],S.[InvoiceId],S.[IsActive],S.[QuoteRequestID],S.[UDF1Label],S.[UDF1Value],S.[UDF2Label],S.[UDF2Value],S.[UDF3Label],S.[UDF3Value],S.[UDF4Label],S.[UDF4Value],S.[UDF5Label],S.[UDF5Value],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
