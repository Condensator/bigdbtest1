SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ESignEnvelopes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EnvelopeId] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Subject] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SentDate] [datetimeoffset](7) NULL,
	[CompletedDate] [datetimeoffset](7) NULL,
	[ESignSystem] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ErrorComment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[Message] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CancellationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DocumentHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TagViewURL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[VaultEnabled] [bit] NOT NULL,
	[XAPIUser] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ESignEnvelopes]  WITH CHECK ADD  CONSTRAINT [EDocumentHeader_ESignEnvelopes] FOREIGN KEY([DocumentHeaderId])
REFERENCES [dbo].[DocumentHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ESignEnvelopes] CHECK CONSTRAINT [EDocumentHeader_ESignEnvelopes]
GO
