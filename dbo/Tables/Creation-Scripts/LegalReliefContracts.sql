SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalReliefContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [date] NULL,
	[Intention] [nvarchar](27) COLLATE Latin1_General_CI_AS NOT NULL,
	[Active] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalReliefContracts]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_LegalReliefContracts] FOREIGN KEY([LegalReliefId])
REFERENCES [dbo].[LegalReliefs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalReliefContracts] CHECK CONSTRAINT [ELegalRelief_LegalReliefContracts]
GO
ALTER TABLE [dbo].[LegalReliefContracts]  WITH CHECK ADD  CONSTRAINT [ELegalReliefContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefContracts] CHECK CONSTRAINT [ELegalReliefContract_Contract]
GO
