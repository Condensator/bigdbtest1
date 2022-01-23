SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractHoldingStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HoldingStatusChange] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatusStartDate] [date] NULL,
	[RNI_Amount] [decimal](16, 2) NULL,
	[RNI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatusComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[UpdatedByDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LastUpdatedByUserId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractHoldingStatusHistories]  WITH CHECK ADD  CONSTRAINT [EContract_ContractHoldingStatusHistories] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractHoldingStatusHistories] CHECK CONSTRAINT [EContract_ContractHoldingStatusHistories]
GO
ALTER TABLE [dbo].[ContractHoldingStatusHistories]  WITH CHECK ADD  CONSTRAINT [EContractHoldingStatusHistory_LastUpdatedByUser] FOREIGN KEY([LastUpdatedByUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ContractHoldingStatusHistories] CHECK CONSTRAINT [EContractHoldingStatusHistory_LastUpdatedByUser]
GO
