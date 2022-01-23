SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ESignEmailContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContactName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[ESignEnvelopeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ESignEmailContacts]  WITH CHECK ADD  CONSTRAINT [EESignEnvelope_ESignEmailContacts] FOREIGN KEY([ESignEnvelopeId])
REFERENCES [dbo].[ESignEnvelopes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ESignEmailContacts] CHECK CONSTRAINT [EESignEnvelope_ESignEmailContacts]
GO
