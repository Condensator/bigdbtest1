CREATE TYPE [dbo].[MasterConfigSetDetail] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MasterConfigDetailId] [bigint] NOT NULL,
	[DraftEntityBatchId] [bigint] NOT NULL,
	[MasterConfigurationSetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
