CREATE TYPE [dbo].[BulkUploadStep] AS TABLE(
	[Type] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Entity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Transaction] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ProcessingOrder] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ScenarioConfigId] [bigint] NULL,
	[BulkUploadProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
