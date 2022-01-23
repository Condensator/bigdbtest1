SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecurityDepositAllocations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAllocation] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GlDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[SecurityDepositId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SecurityDepositAllocations]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_SecurityDepositAllocations] FOREIGN KEY([SecurityDepositId])
REFERENCES [dbo].[SecurityDeposits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SecurityDepositAllocations] CHECK CONSTRAINT [ESecurityDeposit_SecurityDepositAllocations]
GO
ALTER TABLE [dbo].[SecurityDepositAllocations]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositAllocation_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositAllocations] CHECK CONSTRAINT [ESecurityDepositAllocation_Contract]
GO
