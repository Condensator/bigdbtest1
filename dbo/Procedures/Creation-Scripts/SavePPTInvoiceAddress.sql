SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePPTInvoiceAddress]
(
 @val [dbo].[PPTInvoiceAddress] READONLY
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
MERGE [dbo].[PPTInvoiceAddresses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[City]=S.[City],[Description]=S.[Description],[Division]=S.[Division],[HomeAddressLine1]=S.[HomeAddressLine1],[HomeAddressLine2]=S.[HomeAddressLine2],[HomeCity]=S.[HomeCity],[HomeDivision]=S.[HomeDivision],[HomePostalCode]=S.[HomePostalCode],[HomeStateId]=S.[HomeStateId],[IsActive]=S.[IsActive],[IsHeadquarter]=S.[IsHeadquarter],[IsMain]=S.[IsMain],[PostalCode]=S.[PostalCode],[StateId]=S.[StateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[City],[CreatedById],[CreatedTime],[Description],[Division],[HomeAddressLine1],[HomeAddressLine2],[HomeCity],[HomeDivision],[HomePostalCode],[HomeStateId],[IsActive],[IsHeadquarter],[IsMain],[PostalCode],[PPTInvoiceId],[StateId])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[City],S.[CreatedById],S.[CreatedTime],S.[Description],S.[Division],S.[HomeAddressLine1],S.[HomeAddressLine2],S.[HomeCity],S.[HomeDivision],S.[HomePostalCode],S.[HomeStateId],S.[IsActive],S.[IsHeadquarter],S.[IsMain],S.[PostalCode],S.[PPTInvoiceId],S.[StateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
