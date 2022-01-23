CREATE TYPE [dbo].[ReceivableTypeBlendingConfigTable] AS TABLE(
	[EntityType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendContractTypes] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[BlendReceivableSubTypeId] [bigint] NOT NULL,
	[BlendWithReceivableTypeId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
