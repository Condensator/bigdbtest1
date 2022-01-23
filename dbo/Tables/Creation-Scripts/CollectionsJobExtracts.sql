SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollectionsJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[AllocatedQueueId] [bigint] NULL,
	[PrimaryCollectorId] [bigint] NULL,
	[PreviousQueueId] [bigint] NULL,
	[PreviousWorkListId] [bigint] NULL,
	[PreviousWorkListDetailId] [bigint] NULL,
	[IsWorkListIdentified] [bit] NOT NULL,
	[IsWorkListCreated] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsWorkListUnassigned] [bit] NOT NULL,
	[RemitToId] [bigint] NULL,
	[AcrossQueue] [bit] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
