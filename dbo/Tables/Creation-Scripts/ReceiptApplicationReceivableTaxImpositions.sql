SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationReceivableTaxImpositions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountPosted_Amount] [decimal](16, 2) NOT NULL,
	[AmountPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTaxImpositionId] [bigint] NOT NULL,
	[ReceiptApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableTaxImpositions] FOREIGN KEY([ReceiptApplicationId])
REFERENCES [dbo].[ReceiptApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableTaxImpositions] NOCHECK CONSTRAINT [EReceiptApplication_ReceiptApplicationReceivableTaxImpositions]
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [EReceiptApplicationReceivableTaxImposition_ReceivableTaxImposition] FOREIGN KEY([ReceivableTaxImpositionId])
REFERENCES [dbo].[ReceivableTaxImpositions] ([Id])
GO
ALTER TABLE [dbo].[ReceiptApplicationReceivableTaxImpositions] NOCHECK CONSTRAINT [EReceiptApplicationReceivableTaxImposition_ReceivableTaxImposition]
GO
