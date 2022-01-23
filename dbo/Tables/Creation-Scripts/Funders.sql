SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Funders](
	[Id] [bigint] NOT NULL,
	[Type] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[RejectionReasonCode] [nvarchar](25) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[NextReviewDate] [date] NULL,
	[InactivationReason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[W8IssueDate] [date] NULL,
	[W8ExpirationDate] [date] NULL,
	[FATCA] [decimal](5, 0) NULL,
	[Percentage1441] [decimal](5, 0) NULL,
	[ApprovalStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatusPostApproval] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsForFunderLegalEntityAddition] [bit] NOT NULL,
	[IsForFunderEdit] [bit] NOT NULL,
	[IsForFunderRemitToAddition] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Funders]  WITH CHECK ADD  CONSTRAINT [EParty_Funder] FOREIGN KEY([Id])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Funders] CHECK CONSTRAINT [EParty_Funder]
GO
