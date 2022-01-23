SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PTPContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ActivityForCollectionWorkListId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PTPContracts]  WITH CHECK ADD  CONSTRAINT [EActivityForCollectionWorkList_PTPContracts] FOREIGN KEY([ActivityForCollectionWorkListId])
REFERENCES [dbo].[ActivityForCollectionWorkLists] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PTPContracts] CHECK CONSTRAINT [EActivityForCollectionWorkList_PTPContracts]
GO
ALTER TABLE [dbo].[PTPContracts]  WITH CHECK ADD  CONSTRAINT [EPTPContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PTPContracts] CHECK CONSTRAINT [EPTPContract_Contract]
GO
