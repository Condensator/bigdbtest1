SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[UpdateDocuSignEnvelopeStatus]
(
@EnvelopeId NVARCHAR(MAX),
@Status as NVARCHAR(MAX),
@SignersDetails RecipientsDetails READONLY,
@CarboCopyDetails RecipientsDetails READONLY,
@UpdatedById BIGINT,
@EsignSystem NVARCHAR(50),
@DocuSignThirdPartyStatus NVARCHAR(100),
@DocuSignRecipientCompletedStatus NVARCHAR(100),
@SentDate DateTime = Null,
@CompletedDate DateTime = Null
)
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
declare @ESignEnvelopeId BIGINT

select @ESignEnvelopeId = Id from ESignEnvelopes where EnvelopeId = @EnvelopeId and ESignSystem = @EsignSystem 

UPDATE ESignEnvelopes
set Status = @Status,
UpdatedById = @UpdatedById,
UpdatedTime = SYSDATETIMEOFFSET(),
SentDate = Case When @SentDate Is Not Null Then @SentDate Else SentDate End,
CompletedDate = Case When @CompletedDate Is Not Null Then @CompletedDate Else CompletedDate End
where EnvelopeId = @EnvelopeId and ESignSystem = @EsignSystem and IsActive = 1

UPDATE e set 
e.Status = s.Status,
e.UpdatedById = @UpdatedById,
e.UpdatedTime = SYSDATETIMEOFFSET()
from ESignEnvelopeRecipients as e
join @SignersDetails s on s.RecipientId = e.Id and e.IsActive = 1 and e.ESignEnvelopeId = @ESignEnvelopeId

if(@Status = @DocuSignThirdPartyStatus)
BEGIN
	UPDATE e set 
	e.Status = @DocuSignRecipientCompletedStatus,
	e.UpdatedById = @UpdatedById,
	e.UpdatedTime = SYSDATETIMEOFFSET() 
	from ESignEnvelopeRecipients as e
	join @CarboCopyDetails c on c.RecipientId = e.Id and e.IsActive = 1 and e.ESignEnvelopeId = @ESignEnvelopeId
END

END

GO
