CREATE TYPE [dbo].[VertexLocationTaxAreaDetail_Extract] AS TABLE(
	[LocationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxAreaId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[TaxAreaEffectiveDate] [date] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
