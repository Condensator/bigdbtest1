SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalReliefPOCContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Include] [bit] NOT NULL,
	[Active] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[AcceleratedBalanceDetailId] [bigint] NULL,
	[LegalReliefProofOfClaimId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalReliefPOCContracts]  WITH CHECK ADD  CONSTRAINT [ELegalReliefPOCContract_AcceleratedBalanceDetail] FOREIGN KEY([AcceleratedBalanceDetailId])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefPOCContracts] CHECK CONSTRAINT [ELegalReliefPOCContract_AcceleratedBalanceDetail]
GO
ALTER TABLE [dbo].[LegalReliefPOCContracts]  WITH CHECK ADD  CONSTRAINT [ELegalReliefPOCContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefPOCContracts] CHECK CONSTRAINT [ELegalReliefPOCContract_Contract]
GO
ALTER TABLE [dbo].[LegalReliefPOCContracts]  WITH CHECK ADD  CONSTRAINT [ELegalReliefProofOfClaim_LegalReliefPOCContracts] FOREIGN KEY([LegalReliefProofOfClaimId])
REFERENCES [dbo].[LegalReliefProofOfClaims] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalReliefPOCContracts] CHECK CONSTRAINT [ELegalReliefProofOfClaim_LegalReliefPOCContracts]
GO
