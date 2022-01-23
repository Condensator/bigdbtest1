SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalOptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ProposalOption] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProposalOptionTerms] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseFactor] [decimal](8, 4) NOT NULL,
	[RenewalFactor] [decimal](8, 4) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RestockingFee] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProposalExhibitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalOptions]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProposalOptions] FOREIGN KEY([ProposalExhibitId])
REFERENCES [dbo].[ProposalExhibits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalOptions] CHECK CONSTRAINT [EProposalExhibit_ProposalOptions]
GO
