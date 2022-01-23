SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ESignEnvelopeRecipients](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Hierarchy] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecipientAction] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ExternalId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsModified] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ESignEnvelopeRecipients]  WITH CHECK ADD  CONSTRAINT [EESignEnvelope_ESignEnvelopeRecipients] FOREIGN KEY([ESignEnvelopeId])
REFERENCES [dbo].[ESignEnvelopes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ESignEnvelopeRecipients] CHECK CONSTRAINT [EESignEnvelope_ESignEnvelopeRecipients]
GO
