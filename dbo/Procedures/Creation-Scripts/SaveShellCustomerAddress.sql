SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveShellCustomerAddress]
(
 @val [dbo].[ShellCustomerAddress] READONLY
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
MERGE [dbo].[ShellCustomerAddresses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[City]=S.[City],[Division]=S.[Division],[IsShellCustomerAddressCreated]=S.[IsShellCustomerAddressCreated],[LWSystemId]=S.[LWSystemId],[PostalCode]=S.[PostalCode],[SFDCAddressId]=S.[SFDCAddressId],[StateId]=S.[StateId],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[City],[CreatedById],[CreatedTime],[Division],[IsShellCustomerAddressCreated],[LWSystemId],[PostalCode],[SFDCAddressId],[StateId],[UniqueIdentifier])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[City],S.[CreatedById],S.[CreatedTime],S.[Division],S.[IsShellCustomerAddressCreated],S.[LWSystemId],S.[PostalCode],S.[SFDCAddressId],S.[StateId],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
