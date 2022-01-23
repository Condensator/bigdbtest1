SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalContractReplacements](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReplacementAmount_Amount] [decimal](16, 2) NULL,
	[ReplacementAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[RNIAmount_Amount] [decimal](16, 2) NULL,
	[RNIAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalContractReplacements]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalContractReplacements] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalContractReplacements] CHECK CONSTRAINT [EProposal_ProposalContractReplacements]
GO
ALTER TABLE [dbo].[ProposalContractReplacements]  WITH CHECK ADD  CONSTRAINT [EProposalContractReplacement_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ProposalContractReplacements] CHECK CONSTRAINT [EProposalContractReplacement_Contract]
GO
