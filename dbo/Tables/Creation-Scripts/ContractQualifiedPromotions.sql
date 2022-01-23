SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractQualifiedPromotions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ProgramPromotionId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractQualifiedPromotions]  WITH CHECK ADD  CONSTRAINT [EContract_ContractQualifiedPromotions] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractQualifiedPromotions] CHECK CONSTRAINT [EContract_ContractQualifiedPromotions]
GO
ALTER TABLE [dbo].[ContractQualifiedPromotions]  WITH CHECK ADD  CONSTRAINT [EContractQualifiedPromotion_ProgramPromotion] FOREIGN KEY([ProgramPromotionId])
REFERENCES [dbo].[ProgramPromotions] ([Id])
GO
ALTER TABLE [dbo].[ContractQualifiedPromotions] CHECK CONSTRAINT [EContractQualifiedPromotion_ProgramPromotion]
GO
