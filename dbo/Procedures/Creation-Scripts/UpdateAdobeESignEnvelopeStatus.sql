SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create PROCEDURE [dbo].[UpdateAdobeESignEnvelopeStatus]
(
@EnvelopeId NVARCHAR(MAX),
@Status as NVARCHAR(MAX),
@ParticipantsDetails ParticipantsDetails READONLY,
@UpdatedById BIGINT,
@EsignSystem NVARCHAR(50),
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
e.Status = p.Status,
e.UpdatedById = @UpdatedById,
e.UpdatedTime = SYSDATETIMEOFFSET() 
from ESignEnvelopeRecipients as e
join @ParticipantsDetails p on p.ParticipantId = e.Id and e.IsActive = 1 and e.ESignEnvelopeId = @ESignEnvelopeId

END

GO
