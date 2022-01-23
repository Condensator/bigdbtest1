SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionWorkListContractDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsWorkCompleted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[CollectionWorkListId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CompletionReason] [nvarchar](29) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollectionWorkListContractDetails]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkList_CollectionWorkListContractDetails] FOREIGN KEY([CollectionWorkListId])
REFERENCES [dbo].[CollectionWorkLists] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CollectionWorkListContractDetails] CHECK CONSTRAINT [ECollectionWorkList_CollectionWorkListContractDetails]
GO
ALTER TABLE [dbo].[CollectionWorkListContractDetails]  WITH CHECK ADD  CONSTRAINT [ECollectionWorkListContractDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CollectionWorkListContractDetails] CHECK CONSTRAINT [ECollectionWorkListContractDetail_Contract]
GO
