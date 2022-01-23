CREATE TYPE [dbo].[AutoPayoffContract] AS TABLE(
	[IsProcessed] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
